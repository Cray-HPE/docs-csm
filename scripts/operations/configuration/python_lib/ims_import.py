#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
"""Shared Python function library: IMS import"""

import datetime
import inspect
import json
import logging
import os
import tarfile
import tempfile
from typing import Callable, NamedTuple

from . import common
from . import ims
from . import k8s

from .ims_import_export import ExportedData, ImsData, ImsImportExportError, ImsJobsRunning, S3BucketListings


parent_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
ImsPodImportToolPath = os.path.join(parent_dir, "update_ims_data_files.py")


class ImportOptions(NamedTuple):
    tarfile_dir: str
    ignore_running_jobs: bool
    current_ims_data: ImsData
    exported_data: ExportedData

    def verify_no_running_jobs(self) -> None:
        """
        Returns immediately if ignore_running_jobs is True.

        Looks at all of the jobs in the current IMS data and raises an exception if they
        do not all have a status of error or success
        """
        if self.ignore_running_jobs:
            return
        if self.current_ims_data.running_jobs():
            raise ImsJobsRunning()


class DeleteMethods(NamedTuple):
    soft: Callable
    hard: Callable
    deleted: Callable

IMS_DELETE_FUNCS = {
    "image": DeleteMethods(soft=ims.delete_image, hard=ims.hard_delete_image, deleted=ims.delete_deleted_image),
    "public key": DeleteMethods(soft=ims.delete_public_key, hard=ims.hard_delete_public_key,
                                deleted=ims.delete_deleted_public_key),
    "recipe": DeleteMethods(soft=ims.delete_recipe, hard=ims.hard_delete_recipe, deleted=ims.delete_deleted_recipe) }


# The doc string for this function is used in the import script argparse help message
def add_ims_data(import_options: ImportOptions) -> None:
    """Only add exported IMS resources that do not exist"""
    # We do this by removing all overlapping entries from the exported data, and then just
    # calling update_ims_data
    exported_data, current_ims_data = import_options.exported_data, import_options.current_ims_data

    exported_data.ims_data.images.remove_ids(current_ims_data.images)
    exported_data.ims_data.public_keys.remove_ids(current_ims_data.public_keys)
    exported_data.ims_data.recipes.remove_ids(current_ims_data.recipes)

    exported_data.verify_artifact_files_exist(import_options.tarfile_dir)

    do_import(tarfile_dir=import_options.tarfile_dir, current_ims_data=current_ims_data, exported_data=exported_data)


# The doc string for this function is used in the import script argparse help message
def update_ims_data(import_options: ImportOptions) -> None:
    """Add exported IMS resources that do not exist and modify existing resources to match exported resources"""
    exported_data, current_ims_data = import_options.exported_data, import_options.current_ims_data

    exported_data.verify_artifact_files_exist(import_options.tarfile_dir)
    import_options.verify_no_running_jobs()

    # For any images, recipes, or public keys from the exported data which already exist in the current
    # deleted data, we need to delete the deleted version of it, and then refresh the IMS data.
    current_ims_data = delete_deleted_resources(current_ims_data, exported_data.ims_data)

    do_import(tarfile_dir=import_options.tarfile_dir, current_ims_data=current_ims_data, exported_data=exported_data)


# The doc string for this function is used in the import script argparse help message
def overwrite_ims_data(import_options: ImportOptions) -> None:
    """Delete current IMS jobs, hard delete current IMS resources, then add exported resources"""
    exported_data, tarfile_dir = import_options.exported_data, import_options.tarfile_dir
    current_ims_data = import_options.current_ims_data

    exported_data.verify_artifact_files_exist(tarfile_dir)
    import_options.verify_no_running_jobs()

    # First, delete the current IMS images, jobs, recipes, and public keys.
    s3_buckets = S3BucketListings()
    def delete_all(label: str, current: ims.ImsObjectMap, deleted: ims.ImsObjectMap) -> None:
        hard_delete = IMS_DELETE_FUNCS[label].hard
        delete_deleted = IMS_DELETE_FUNCS[label].deleted

        # Check if the hard delete function takes the "remove_s3" argument
        remove_s3_arg = "remove_s3" in inspect.signature(hard_delete).parameters
        logging.info("Deleting IMS %ss (this may take a while)", label)
        for ims_id in deleted:
            logging.debug("Deleting deleted IMS %s %s", label, ims_id)
            delete_deleted(ims_id)

        for ims_id, ims_obj in current.items():
            logging.debug("Hard deleting IMS %s %s", label, ims_id)
            if remove_s3_arg:
                s3_url = ims.get_s3_url(ims_obj)
                hard_delete(ims_id, remove_s3=s3_buckets.artifact_exists(s3_url=s3_url, load_if_needed=True))
            else:
                hard_delete(ims_id)

    delete_all("image", current=current_ims_data.images, deleted=current_ims_data.deleted.images)
    delete_all("public key", current=current_ims_data.public_keys, deleted=current_ims_data.deleted.public_keys)
    delete_all("recipe", current=current_ims_data.recipes, deleted=current_ims_data.deleted.recipes)

    logging.info("Deleting IMS jobs")
    for ims_id in current_ims_data.jobs:
        logging.debug("Deleting IMS job %s", ims_id)
        ims.delete_job(ims_id)

    # Refresh the current IMS data and validate that no deleted or non-deleted objects exist
    logging.info("Reloading data from IMS")
    current_ims_data = ImsData.load_from_system(include_deleted=True)
    if current_ims_data.images:
        raise ImsImportExportError("IMS images still exist even after deleting them all")
    if current_ims_data.deleted.images:
        raise ImsImportExportError("Deleted IMS images still exist even after deleting them all")
    if current_ims_data.jobs:
        raise ImsImportExportError("IMS jobs still exist even after deleting them all")
    if current_ims_data.public_keys:
        raise ImsImportExportError("IMS public keys still exist even after deleting them all")
    if current_ims_data.deleted.public_keys:
        raise ImsImportExportError("Deleted IMS public keys still exist even after deleting them all")
    if current_ims_data.recipes:
        raise ImsImportExportError("IMS recipes still exist even after deleting them all")
    if current_ims_data.deleted.recipes:
        raise ImsImportExportError("Deleted IMS recipes still exist even after deleting them all")

    do_import(tarfile_dir=tarfile_dir, current_ims_data=current_ims_data, exported_data=exported_data)


# The doc string for this function is used in the import script argparse help message
def soft_overwrite_ims_data(import_options: ImportOptions) -> None:
    """Delete current IMS jobs, soft delete current IMS resources, then add exported resources"""
    exported_data, tarfile_dir = import_options.exported_data, import_options.tarfile_dir
    current_ims_data = import_options.current_ims_data

    exported_data.verify_artifact_files_exist(tarfile_dir)
    import_options.verify_no_running_jobs()

    # First, delete the current IMS images, jobs, recipes, and public keys.
    # For those whose IDs do not conflict with ones being imported, we soft delete them.
    # For any whose IDs do conflict with ones being imported, they must be hard deleted.
    s3_buckets = S3BucketListings()
    def delete_conflicts(label: str, current: ims.ImsObjectMap, deleted: ims.ImsObjectMap,
                         exported: ims.ImsObjectMap) -> None:
        hard_delete = IMS_DELETE_FUNCS[label].hard
        soft_delete = IMS_DELETE_FUNCS[label].soft
        delete_deleted = IMS_DELETE_FUNCS[label].deleted

        # Check if the hard delete function takes the "remove_s3" argument
        remove_s3_arg = "remove_s3" in inspect.signature(hard_delete).parameters
        logging.info("Deleting IMS %ss (this may take a while)", label)
        for ims_id in deleted:
            if ims_id in exported:
                # This deleted resource needs to be deleted
                logging.debug("Deleting deleted IMS %s %s", label, ims_id)
                delete_deleted(ims_id)

        for ims_id, ims_obj in current.items():
            if ims_id in exported:
                # This resource needs to be hard deleted
                logging.debug("Hard deleting IMS %s %s", label, ims_id)
                if remove_s3_arg:
                    s3_url = ims.get_s3_url(ims_obj)
                    hard_delete(ims_id, remove_s3=s3_buckets.artifact_exists(s3_url=s3_url, load_if_needed=True))
                else:
                    hard_delete(ims_id)
            else:
                # Soft delete this resource
                logging.debug("Soft deleting IMS %s %s", label, ims_id)
                soft_delete(ims_id)

    delete_conflicts("image", current=current_ims_data.images, deleted=current_ims_data.deleted.images,
                     exported=exported_data.ims_data.images)
    delete_conflicts("public key", current=current_ims_data.public_keys, deleted=current_ims_data.deleted.public_keys,
                     exported=exported_data.ims_data.public_keys)
    delete_conflicts("recipe", current=current_ims_data.recipes, deleted=current_ims_data.deleted.recipes,
                     exported=exported_data.ims_data.recipes)

    logging.info("Deleting IMS jobs")
    for ims_id in current_ims_data.jobs:
        logging.debug("Deleting IMS job %s", ims_id)
        ims.delete_job(ims_id)

    # Refresh the current IMS data and validate that no non-deleted objects exist
    logging.info("Reloading data from IMS")
    current_ims_data = ImsData.load_from_system(include_deleted=True)
    if current_ims_data.images:
        raise ImsImportExportError("IMS images still exist even after deleting them all")
    if current_ims_data.jobs:
        raise ImsImportExportError("IMS jobs still exist even after deleting them all")
    if current_ims_data.public_keys:
        raise ImsImportExportError("IMS public keys still exist even after deleting them all")
    if current_ims_data.recipes:
        raise ImsImportExportError("IMS recipes still exist even after deleting them all")

    do_import(tarfile_dir=tarfile_dir, current_ims_data=current_ims_data, exported_data=exported_data)


IMPORT_FUNCTIONS = {
    "add": add_ims_data,
    "update": update_ims_data,
    "overwrite": overwrite_ims_data,
    "soft_overwrite": soft_overwrite_ims_data }


def do_import(tarfile_dir: str,
              current_ims_data: ImsData,
              exported_data: ExportedData) -> None:
    """
    Import exported_data from tarfile_dir
    """
    if not exported_data.ims_data.any_images_keys_recipes:
        logging.info("No IMS data to import")

        # But there may be S3 artifacts to upload
        logging.info("Uploading S3 artifacts (if any)")
        exported_data.update_s3(tarfile_dir)

        return

    # Update current IMS data with exported IMS data
    current_ims_data.update_with_exported_data(exported_data.ims_data)

    # Upload S3 artifacts, if applicable
    exported_data.update_s3(tarfile_dir)

    # Create temporary directory inside IMS pod
    logging.debug("Looking up IMS pod name")
    ims_pod_name = get_ims_pod_name()
    logging.info("Copying files to IMS Kubernetes pod (%s)", ims_pod_name)
    result = common.run_command(["kubectl", "exec", "-n", "services", ims_pod_name, "--", "mktemp", "-d"])
    pod_tmpdir = result.decode().strip()
    if not pod_tmpdir:
        raise common.ScriptException("No output when creating temporary directory in IMS pod")
    logging.debug("Pod temporary directory created: '%s'", pod_tmpdir)

    # Write JSON file with IMS images, keys, and recipes to import
    ims_data = { "images": current_ims_data.images.ims_object_list,
                 "public_keys": current_ims_data.public_keys.ims_object_list,
                 "recipes": current_ims_data.recipes.ims_object_list }

    logging.debug("Writing new IMS data to JSON file")
    temp_export_datafile = tempfile.mkstemp(prefix="exported-ims-data-", suffix=".json")[1]
    with open(temp_export_datafile, "wt") as tfile:
        json.dump(ims_data, tfile)

    # Copy JSON file to tmpdir in pod
    logging.debug("Copying IMS data JSON file to pod")
    datafile_path_in_pod = os.path.join(pod_tmpdir, "data.json")
    common.run_command(["kubectl", "cp", "-n", "services", temp_export_datafile,
                        f"{ims_pod_name}:{datafile_path_in_pod}"])

    # Clean up local copy of JSON file
    os.remove(temp_export_datafile)

    logging.debug("Copying import tool to IMS pod")
    tool_path_in_pod = os.path.join(pod_tmpdir, "import.py")
    # Copy import tool to tmpdir in pod
    common.run_command(["kubectl", "cp", "-n", "services", ImsPodImportToolPath, f"{ims_pod_name}:{tool_path_in_pod}"])

    logging.info("Updating data in IMS")
    # Execute import tool in pod
    common.run_command(["kubectl", "exec", "-n", "services", ims_pod_name, "--", "python3", tool_path_in_pod])

    # Restart IMS to pick up imported changes
    logging.info("Initiating rolling restart of IMS Kubernetes deployment")
    common.run_command(["kubectl", "rollout", "restart", "deployment", "-n", "services", "cray-ims"])
    logging.info("Waiting for rolling restart to complete (this may take a few minutes)")
    common.run_command(["kubectl", "rollout", "status", "deployment", "-n", "services", "cray-ims"])


def delete_deleted_resources(current: ImsData, export: ImsData) -> ImsData:
    """
    For images, public_keys, and recipes:
    This function looks for any exported resource IDs which are in the current deleted resources.
    For any that it finds, it hard deletes them from IMS. This is to prevent them from existing in
    both the regular resource list and deleted resource list, after the import.

    If nothing is deleted, this function returns the unchanged current_ims_data.
    If any are deleted, then after all deletes are done, the current IMS data will be refreshed
    and returned.
    """
    def delete_conflicts(label: str, deleted_resources: ims.ImsObjectMap, exported_resources: ims.ImsObjectMap) -> None:
        deletes = False
        logging.info("Deleting any deleted %ss with overlapping IDs of ones being imported", label)
        for ims_id in exported_resources:
            if ims_id in deleted_resources:
                logging.debug("Deleting deleted IMS %s %s", label, ims_id)
                IMS_DELETE_FUNCS[label].deleted(ims_id)
                deletes=True
        return deletes

    deletes_done = delete_conflicts("image", current.deleted.images, export.images)
    if delete_conflicts("public key", current.deleted.public_keys, export.public_keys):
        deletes_done = False
    if delete_conflicts("recipe", current.deleted.recipes, export.recipes):
        deletes_done = False

    if deletes_done:
        # Refresh the current IMS data
        logging.info("Reloading data from IMS")
        return ImsData.load_from_system(include_deleted=True)

    return current


def get_ims_pod_name() -> str:
    """
    Looks up the name of the IMS Kubernetes pod and returns it.
    """
    ims_pods = k8s.Client().client.list_namespaced_pod(namespace="services",
                                                       label_selector="app.kubernetes.io/instance=cray-ims")
    if len(ims_pods.items) != 1:
        raise common.ScriptException(f"Expect to find exactly one cray-ims pod but found {len(ims_pods.items)}")
    ims_pod_name = ims_pods.items[0].metadata.name
    if not ims_pod_name:
        raise common.ScriptException("Empty name found for cray-ims pod")
    return ims_pod_name


def expand_tarfile(tarfile_path: str, target_dir: str) -> str:
    """
    Make sure there is enough space to expand the tarfile, then expand it.
    Return the path to the directory where it was expanded.
    """
    # Make sure we appear to have enough space to do this
    # We will make sure the target directory has an amount of free space at least equal to
    # the size of the tar archive plus 10M overhead
    tar_size_bytes = os.path.getsize(tarfile_path)
    common.verify_free_space_in_dir(target_dir, tar_size_bytes + 10*1024*1024)

    # Create output directory
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
    tarfile_dir = tempfile.mkdtemp(prefix=f"import-ims-data-{timestamp}-", dir=target_dir)

    # Expand tar archive into output directory
    logging.info("Extracting '%s' into directory '%s' (this may take a while)", tarfile_path, tarfile_dir)
    with tarfile.open(tarfile_path, mode='r') as tfile:
        tfile.extractall(tarfile_dir)
    logging.info("Extraction complete")
    return tarfile_dir
