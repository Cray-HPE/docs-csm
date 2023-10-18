#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

from . import common

from .ims_import_export import ExportedData, EXPORTED_DATA_FILENAME


def do_export(ignore_running_jobs: bool, include_deleted: bool, exclude_linked_artifacts: bool,
              target_directory: str) -> Tuple[ExportedData, str]:
    """
    1. Creates a directory for the exported data
    2. Collects current IMS data and writes it to a file (including data for the deleted resources, if specified)
    3. If specified, downloads the associated S3 artifacts
    4. Creates a tarfile containing all of this
    5. Returns the data exported from IMS and the path to the tarfile
    """
    # Create output directory
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
    outdir = tempfile.mkdtemp(prefix=f"export-ims-data-{timestamp}-", dir=target_directory)

    file_list = []
    if exclude_linked_artifacts:
        exported_data = ExportedData.load_from_system(ignore_running_jobs=ignore_running_jobs,
                                                      include_deleted=include_deleted, s3_directory=None)
    else:
        exported_data = ExportedData.load_from_system(ignore_running_jobs=ignore_running_jobs,
                                                      include_deleted=include_deleted, s3_directory=outdir)
        file_list.extend(exported_data.s3_data.downloaded_artifact_relpaths)

    # Write exported data to a file
    exported_data_file = os.path.join(outdir, EXPORTED_DATA_FILENAME)
    with open(exported_data_file, "wt") as jsonfile:
        json.dump(exported_data.jsondict, jsonfile)
    file_list.append(EXPORTED_DATA_FILENAME)

    tarfile_path = tempfile.mkstemp(prefix=f"export-ims-data-{timestamp}-", suffix=".tar", dir=target_directory)[1]
    # Create tar archive of all files
    write_tarfile(tarfile_path, outdir, file_list)

    logging.info("Data saved to tar archive: %s", tarfile_path)
    # Now we should be able to remove outdir
    logging.debug("Removing directory %s", outdir)
    os.rmdir(outdir)
    return exported_data, tarfile_path


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
