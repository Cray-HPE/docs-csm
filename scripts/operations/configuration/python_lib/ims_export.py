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
from typing import List, Tuple, Union

from . import common

from .ims_import_export import ExportedData, EXPORTED_DATA_FILENAME

class ExportOptions:
    def __init__(self,
                 target_directory: str,
                 ignore_running_jobs: bool = False,
                 include_deleted: bool = False,
                 exclude_linked_artifacts: bool = False,
                 exclude_links_from_bos: Union[bool, None] = None,
                 exclude_links_from_bss: Union[bool, None] = None,
                 exclude_links_from_product_catalog: Union[bool, None] = None,
                 no_tar: Union[bool, None] = None):
        self.__target_directory = target_directory
        self.__ignore_running_jobs = ignore_running_jobs
        self.__include_deleted = include_deleted
        self.__exclude_linked_artifacts = exclude_linked_artifacts
        if exclude_linked_artifacts:
            if exclude_links_from_bos is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from BOS")
            self.__include_bos = False

            if exclude_links_from_bss is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from BSS")
            self.__include_bss = False

            if exclude_links_from_product_catalog is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from product catalog")
            self.__include_product_catalog = False

            if no_tar is not True:
                logging.debug("Excluding linked artifacts -> will not create tar file")
            self.__create_tarfile = False
            return

        if exclude_links_from_bos is not None:
            self.__include_bos = not exclude_links_from_bos
        else:
            logging.debug("Including linked artifacts -> also include S3 links from BOS")
            self.__include_bos = True

        if exclude_links_from_bss is not None:
            self.__include_bss = not exclude_links_from_bss
        else:
            logging.debug("Including linked artifacts -> also include S3 links from BSS")
            self.__include_bss = True

        if exclude_links_from_product_catalog is not None:
            self.__include_product_catalog = not exclude_links_from_product_catalog
        else:
            logging.debug("Including linked artifacts -> also include S3 links from product_catalog")
            self.__include_product_catalog = True

        if no_tar is not None:
            self.__create_tarfile = not no_tar
        else:
            logging.debug("Including linked artifacts -> also create tar file of exported data")
            self.__create_tarfile = True

    @property
    def ignore_running_jobs(self) -> bool:
        return self.__ignore_running_jobs

    @property
    def include_deleted(self) -> bool:
        return self.__include_deleted

    @property
    def exclude_linked_artifacts(self) -> bool:
        return self.__exclude_linked_artifacts

    @property
    def target_directory(self) -> str:
        return self.__target_directory

    @property
    def include_bos(self) -> bool:
        return self.__include_bos

    @property
    def include_bss(self) -> bool:
        return self.__include_bss

    @property
    def include_product_catalog(self) -> bool:
        return self.__include_product_catalog

    @property
    def create_tarfile(self) -> bool:
        return self.__create_tarfile


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
