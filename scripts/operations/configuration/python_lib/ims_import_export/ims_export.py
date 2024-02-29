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
"""Shared Python function library: IMS export"""

import datetime
import json
import logging
import os
import tarfile
import tempfile
from typing import List, Tuple

from python_lib import common

from .defs import EXPORTED_DATA_FILENAME
from .export_options import ExportOptions
from .exported_data import ExportedData

def do_export(options: ExportOptions) -> Tuple[ExportedData, str]:
    """
    1. Creates a directory for the exported data
    2. Collects current IMS data and writes it to a file (including data for the deleted resources, if specified)
    3. If specified, downloads the associated S3 artifacts
    4. If no_tar and exclude_linked_artifacts are both False, creates a tarfile containing all of this
    5. Returns the data exported from IMS and the path to the tarfile (if no_tar and exclude_linked_artifacts are
       False) or the root of the exported data directory (if no_tar or exclude_linked_artifacts is True)
    """
    # Create output directory
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
    outdir = tempfile.mkdtemp(prefix=f"export-ims-data-{timestamp}-", dir=options.target_directory)

    load_from_system_kwargs = {
        "create_tarfile": options.create_tarfile,
        "ignore_running_jobs": options.ignore_running_jobs,
        "include_bos": options.include_bos,
        "include_bss": options.include_bss,
        "include_product_catalog": options.include_product_catalog,
        "include_deleted": options.include_deleted }
    if options.exclude_linked_artifacts:
        exported_data = ExportedData.load_from_system(s3_directory=None, **load_from_system_kwargs)
    else:
        exported_data = ExportedData.load_from_system(s3_directory=outdir, **load_from_system_kwargs)
        if options.create_tarfile:
            file_list = list(exported_data.s3_data.downloaded_artifact_relpaths)

    # Write exported data to a file
    exported_data_file = os.path.join(outdir, EXPORTED_DATA_FILENAME)
    with open(exported_data_file, "wt") as jsonfile:
        json.dump(exported_data.jsondict, jsonfile)

    if options.create_tarfile:
        file_list.append(EXPORTED_DATA_FILENAME)

        tarfile_path = tempfile.mkstemp(prefix=f"export-ims-data-{timestamp}-", suffix=".tar", dir=options.target_directory)[1]
        # Create tar archive of all files
        write_tarfile(tarfile_path, outdir, file_list)

        logging.info("Data saved to tar archive: %s", tarfile_path)

        # Now we should be able to remove outdir
        logging.debug("Removing directory %s", outdir)
        os.rmdir(outdir)
        return exported_data, tarfile_path

    logging.info("Data saved in directory: %s", outdir)
    return exported_data, outdir


def estimate_export_size(options: ExportOptions) -> None:
    """
    Does basically the same thing as do_export, up to the point where it knows the total size of the S3
    artifacts to be included in the export. At that point, print out the estimated total size of the exported
    data, and then return.
    """
    # Create output directory
    load_from_system_kwargs = {
        "create_tarfile": options.create_tarfile,
        "ignore_running_jobs": options.ignore_running_jobs,
        "include_bos": options.include_bos,
        "include_bss": options.include_bss,
        "include_product_catalog": options.include_product_catalog,
        "include_deleted": options.include_deleted }

    if options.exclude_linked_artifacts:
        estimated_size_bytes = ExportedData.estimate_size(s3_directory=None, **load_from_system_kwargs)
    else:
        timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
        with tempfile.TemporaryDirectory(prefix=f"estimate-size-export-ims-data-{timestamp}-", dir=options.target_directory) as outdir:
            estimated_size_bytes = ExportedData.estimate_size(s3_directory=outdir, **load_from_system_kwargs)

    logging.info("With specified export options, estimated total export size is: %s", common.sizeof_fmt(estimated_size_bytes))


def write_tarfile(tarfile_path: str, basedir: str, file_list: List[str]) -> None:
    """
    Creates tar file with path tarfile_path. Add all files in file_list, which are relative paths from basedir.
    As each file is added, delete it.
    """
    logging.info("Creating tar archive: %s", tarfile_path)
    with common.set_directory(basedir):
        with tarfile.open(tarfile_path, mode='w') as tfile:
            for rel_file_path in file_list:
                logging.info("Adding to tar archive: %s", rel_file_path)
                tfile.add(rel_file_path)
                logging.debug("Deleting: %s", rel_file_path)
                os.remove(rel_file_path)
                # Clean up directories as we go (ignoring failures, as they may not yet be empty)
                try:
                    os.removedirs(os.path.dirname(rel_file_path))
                    logging.debug("Removed directory: %s", os.path.dirname(rel_file_path))
                except OSError:
                    pass
