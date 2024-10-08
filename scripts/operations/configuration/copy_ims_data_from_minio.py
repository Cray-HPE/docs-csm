#! /usr/bin/env python3
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

"""
Download exported IMS data from Minio into local filesystems, so it can
be imported later
"""

import datetime
import logging
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile

from typing import Callable, List, NamedTuple, Tuple

from python_lib import common
from python_lib import logger

IMS_EXPORT_FS="/opt/cray/pit/ims"
IMS_EXPORT_DIR=os.path.join(IMS_EXPORT_FS, "exported-ims-data")
CLEANUP_SCRIPT_BASENAME="cleanup.sh"
IMS_CLEANUP_SCRIPT_PATH=os.path.join(IMS_EXPORT_DIR, CLEANUP_SCRIPT_BASENAME)

LOG_DIR = "/var/log/copy_ims_data_from_minio"
os.makedirs(LOG_DIR, exist_ok=True)

class Artifact(NamedTuple):
    """
    An IMS artifact in Minio
    """

    # The path excludes the 'ims/export-ims-data-...' prefix
    path: str
    size_bytes: int

    @property
    def dirname(self) -> str:
        """
        Return just the directory portion of the artifact path
        """
        return os.path.dirname(self.path)


class InsufficientSpace(Exception):
    """
    Raised when trying to configure a destination directory that doesn't have enough free space.
    """

class DestinationDirectory:
    """
    A local directory on the system into which we will download IMS artifacts from minio.
    """

    def __init__(self, base_dir: str, min_gb: int=0, max_pct: int=0, require_1gb_avail: bool=True):
        """
        min_gb is the minimum free space we will allow to happen after we copy files (that is, we
        will not copy in files that would bring us under this).

        max_pct is the maximum used space percentage we will allow to happen after we copy files.

        If require_1gb_avail is True, we will not use a directory if it doesn't have at least
        min_gb + 1 GB available currently. In other words, we want to make sure it has some room for
        us to copy files, or we won't even bother with it.

        Raise InsufficientSpace exception if there is not enough space
        """
        logging.debug("DestinationDirectory: base_dir=%s min_gb=%d max_pct=%d require_1gb_avail=%s",
                      base_dir, min_gb, max_pct, require_1gb_avail)
        min_bytes = min_gb*1024*1024*1024
        usg = shutil.disk_usage(base_dir)
        logging.debug("'%s' has %d free bytes, %d used bytes, and %d total bytes",
                      base_dir, usg.free, usg.used, usg.total)
        if max_pct > 0:
            min_bytes = max(min_bytes, math.ceil(usg.total*(100-max_pct)/100.0))
        orig_avail_bytes = usg.free - min_bytes
        if require_1gb_avail:
            min_orig_avail = 1024*1024*1024
        else:
            min_orig_avail = 0
        if orig_avail_bytes < min_orig_avail:
            raise InsufficientSpace()
        logging.debug("Creating directory under '%s'", base_dir)
        if base_dir == IMS_EXPORT_FS:
            os.mkdir(IMS_EXPORT_DIR)
            self.__path = IMS_EXPORT_DIR
        else:
            self.__path = tempfile.mkdtemp(prefix="exported-ims-data-", dir=base_dir)
        logging.info("Created directory '%s'", self.__path)
        self.__artifacts = []
        self.__orig_avail_bytes = orig_avail_bytes

    @property
    def is_main_dir(self) -> bool:
        """
        Return True if this is the main IMS export directory.
        Otherwise return False
        """
        return self.__path == IMS_EXPORT_DIR

    @property
    def path(self) -> str:
        """
        Return the path to this directory
        """
        return self.__path

    @property
    def artifacts(self) -> List[Artifact]:
        """
        Return the list of artifacts assigned to this directory
        """
        # Return a copy of the list so that we can be sure we're the only ones adding to it
        return list(self.__artifacts)

    @property
    def total_artifact_size(self) -> int:
        """
        Return the total size in bytes of all artifacts assigned to this directory
        """
        return sum([a.size_bytes for a in self.artifacts])

    def print_artifact_summary(self) -> str:
        """
        Print a summary of all artifacts assigned to this directory
        """
        total_size = self.total_artifact_size
        if total_size < 1024:
            size_str = f"{total_size} bytes"
        elif total_size < 1024*1024:
            size_str = f"{total_size//1024} KB"
        elif total_size < 1024*1024*1024:
            size_str = f"{total_size//1024//1024} MB"
        else:
            size_str = f"{total_size//1024//1024//1024} GB"
        logging.info("%s: Will store %s (%d artifacts)", self.path, size_str, len(self.artifacts))

    @property
    def avail_bytes(self) -> int:
        """
        Amount of bytes available in this directory, given all of the assigned artifacts and our
        minimum allowed free space limit.
        """
        return self.__orig_avail_bytes - self.total_artifact_size

    def add_artifact(self, art: Artifact) -> bool:
        """
        Returns False if not enough space
        """
        if art.size_bytes > self.avail_bytes:
            return False
        self.__artifacts.append(art)
        return True

    def sync_from_minio(self, folder_name: str) -> None:
        """
        Sync all of the assigned artifacts from minio to this directory.
        If this is not the main export directory, also create symlinks in the
        main export directory for these artifacts.
        """
        if not self.artifacts:
            return
        include_args = []
        for art in self.artifacts:
            include_args.extend(["--include", art.path])
        logging.info("Copying selected artifacts from minio to '%s'", self.path)
        run_aws_s3_cmd("sync", f"s3://cms/{folder_name}", self.path, "--exclude", "*",
                       *include_args, num_retries=5, timeout=14400)
        if self.is_main_dir:
            return
        logging.info("Creating symbolic links in main export directory to files under '%s'",
                     self.path)
        for art in self.artifacts:
            # Create a symbolic link for this artifact in the main export directory
            if art.dirname:
                dirname = os.path.join(IMS_EXPORT_DIR, art.dirname)
                logging.debug("Creating directory (if needed): '%s'", dirname)
                os.makedirs(dirname, exist_ok=True)
            create_symlink(symlink_src_path=os.path.join(self.path, art.path),
                           symlink_dst_path=os.path.join(IMS_EXPORT_DIR, art.path))


class LocalDirList:
    """
    Class to manage our list of local directories which we will use to populated
    the exported IMS data from minio
    """

    def __init__(self, ims_export_dir: DestinationDirectory):
        self.__local_dirs = [ ims_export_dir ]

    @property
    def ims_export_dir(self) -> DestinationDirectory:
        """
        Return the main IMS import directory
        """
        return self.__local_dirs[0]

    @property
    def __non_main_dirs(self) -> List[DestinationDirectory]:
        """
        Return all local dirs except the main IMS import directory
        """
        return self.__local_dirs[1:]

    def add_dir(self, *args, **kwargs):
        """
        Create a destination directory using the specified arguments.
        If there is insufficient space, oh well, otherwise add it to our list.
        """
        try:
            self.__local_dirs.append(DestinationDirectory(*args, **kwargs))
        except InsufficientSpace:
            pass

    @property
    def artifacts(self) -> List[Artifact]:
        return [ a for ldir in self.__local_dirs for a in ldir.artifacts ]

    def priority(self, ldir: DestinationDirectory) -> int:
        """
        The higher the number, the less our tool wants to copy artifacts into this directory.
        Used as a mechanism to balance the data out across multiple directories, and to
        put much less of it on the USB drive.
        """
        if ldir.is_main_dir:
            return len(self.artifacts)+1
        return len(ldir.artifacts)

    def add_artifact(self, art: Artifact) -> None:
        """
        Exit script in error if no directory has enough room
        """
        for ldir in sorted(self.__local_dirs, key=self.priority):
            if ldir.add_artifact(art):
                return
        logging.error("Insufficient free space to copy IMS data from minio")
        sys.exit(1)

    def sync_from_minio(self, folder_name: str) -> None:
        """
        Call sync_from_minio method on ims_export_dir and each of our local directories
        """
        for ldir in self.__local_dirs:
            ldir.sync_from_minio(folder_name)

    def print_artifact_summary(self) -> None:
        """
        Call print_artifact_summary method on ims_export_dir and each of our local directories
        """
        for ldir in self.__local_dirs:
            ldir.print_artifact_summary()

    def assign_artifacts(self, all_artifacts: List[Artifact]) -> None:
        """
        Sort the artifacts from largest to smallest and assign them each to a destination
        directory.
        Then print a summary of how much has been assigned to each directory.
        """
        logging.info("Determining download location for each artifact")
        for artifact in sorted(all_artifacts, key=lambda a: a.size_bytes, reverse=True):
            self.add_artifact(artifact)
        self.print_artifact_summary()

    def create_cleanup_script(self):
        """
        Create the cleanup script and make the file executable
        """
        logging.debug("Creating cleanup script")
        with open(IMS_CLEANUP_SCRIPT_PATH, "wt") as f:
            f.write(f"#!/usr/bin/env bash\n\n# Automatically generated by {sys.argv[0]}\n")
            for ldir in self.__non_main_dirs:
                f.write(f'[[ -d "{ldir.path}" ]] && rm -rf "{ldir.path}"\n')
            f.write(f'rm -rf "{self.ims_export_dir.path}"\n')
            f.write("echo Cleanup done\n")
        logging.debug("Making cleanup script executable")
        common.run_command(["chmod", "+x", IMS_CLEANUP_SCRIPT_PATH], timeout=30, num_retries=3)


def create_symlink(symlink_src_path: str, symlink_dst_path: str) -> None:
    """
    Create symbolic link
    """
    logging.debug("Creating symbolic link '%s' -> '%s'", symlink_dst_path, symlink_src_path)
    os.symlink(symlink_src_path, symlink_dst_path)


def run_aws_s3_cmd(*aws_s3_args, **run_command_kwargs) -> bytes:
    """
    Wrapper for common.run_command to run aws s3 commands against minio
    """
    command_list = ["/usr/bin/aws", "s3"]
    command_list.extend(aws_s3_args)
    command_list.extend(["--endpoint-url", "http://ncn-m001.nmn:8000"])
    return common.run_command(command_list, **run_command_kwargs)


def run_cleanup_script():
    """
    Run cleanup script, if it exists
    """
    if not os.path.isfile(IMS_CLEANUP_SCRIPT_PATH):
        logging.debug("Cleanup script '%s' does not exist or is not a regular file",
                      IMS_CLEANUP_SCRIPT_PATH)
        return

    logging.info("Running cleanup script '%s'", IMS_CLEANUP_SCRIPT_PATH)
    clean_timeout_seconds=900
    try:
        subprocess.run([IMS_CLEANUP_SCRIPT_PATH], check=True, timeout=clean_timeout_seconds)
    except subprocess.CalledProcessError:
        logging.error("IMS cleanup script failed")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        logging.error("IMS cleanup script killed because it had not completed after %d seconds",
                      clean_timeout_seconds)
        sys.exit(1)
    logging.debug("Cleanup script completed successfully")


def create_minio_list_re_match() -> Callable:
    """
    Return the regular expression match function to be used when parsing the minio listing
    """
    date_re = r'[2-9][0-9]{3}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[0-1])'
    time_re = r'(?:[0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]'
    size_re = r'(0|[1-9][0-9]*)'
    path_re = r'(ims/export-ims-data-[^/]+)/(.+[^ \t])'
    space_re = r'[ \t]+'
    minio_list_line_re = r'^' + space_re.join([date_re, time_re, size_re, path_re]) + r'[ \t]*$'
    return re.compile(minio_list_line_re).match


def get_artifacts_list_from_minio() -> Tuple[str, List[Artifact]]:
    """
    List the IMS data in Minio and parse it into an artifact list
    """
    minio_list_line_match = create_minio_list_re_match()
    logging.info("Getting IMS export artifact listing from minio")
    minio_listing = run_aws_s3_cmd("ls", "s3://cms/ims", "--recursive", num_retries=5, timeout=120)

    logging.info("Parsing artifact listing")
    all_artifacts = []
    folder_name = None
    for line in minio_listing.decode().split('\n'):
        # Skip empty lines
        if not line:
            continue
        re_match = minio_list_line_match(line)
        if not re_match:
            logging.error("S3 listing does not conform to expected format: %s", line)
            sys.exit(1)
        if folder_name is None:
            folder_name = re_match[2]
        elif folder_name != re_match[2]:
            logging.error("Multiple IMS export data folders found in minio: '%s', '%s'",
                          folder_name, re_match[2])
            sys.exit(1)
        all_artifacts.append(Artifact(path=re_match[3], size_bytes=int(re_match[1])))
    if folder_name is None:
        logging.error("No IMS artifacts found in minio")
        sys.exit(1)
    return folder_name, all_artifacts


def create_main_export_dir(logfile_path: str) -> DestinationDirectory:
    """
    Cleanup up the current export directory, if applicable, and then create a new one.
    Create a symlink to the script log file in the directory, to document how it was populated.
    """
    # Run cleanup script, if it exists
    run_cleanup_script()

    # Remove contents of IMS_EXPORT_DIR, if it exists
    if os.path.isdir(IMS_EXPORT_DIR):
        logging.info("Removing directory '%s' and its contents (if any)", IMS_EXPORT_DIR)
        shutil.rmtree(IMS_EXPORT_DIR)
        logging.debug("Directory removed")

    # Create IMS_EXPORT_DIR
    try:
        ims_export_dir = DestinationDirectory(base_dir=IMS_EXPORT_FS, require_1gb_avail=False)
    except InsufficientSpace:
        logging.error("Insufficient free space in '%s'", IMS_EXPORT_FS)
        sys.exit(1)
    create_symlink(symlink_src_path=logfile_path,
                   symlink_dst_path=os.path.join(IMS_EXPORT_DIR, "log.txt"))
    return ims_export_dir


def create_local_directories(logfile_path: str) -> LocalDirList:
    """
    Create directories on other local drives that have sufficient space.
    """
    ims_export_dir = create_main_export_dir(logfile_path)
    local_dir_list = LocalDirList(ims_export_dir)
    local_dir_list.add_dir(base_dir="/root", max_pct=70)
    local_dir_list.add_dir(base_dir="/var/lib/s3fs_cache", min_gb=1)
    local_dir_list.add_dir(base_dir="/metal/recovery", max_pct=75, require_1gb_avail=False)
    local_dir_list.create_cleanup_script()
    return local_dir_list


def validate_export_dirs() -> None:
    """
    Makes sure that IMS_IMPORT_FS exists and is a directory
    Makes sure that either IMS_EXPORT_DIR does not exist, or exists and is a directory
    """
    if not os.path.exists(IMS_EXPORT_FS):
        logging.error("Does not exist: '%s'", IMS_EXPORT_FS)
        sys.exit(1)
    if not os.path.isdir(IMS_EXPORT_FS):
        logging.error("Exists but is not a directory: '%s'", IMS_EXPORT_FS)
        sys.exit(1)
    logging.debug("Directory exists: '%s'", IMS_EXPORT_FS)

    if os.path.isdir(IMS_EXPORT_DIR):
        logging.debug("Directory exists: '%s'", IMS_EXPORT_DIR)
        return
    if not os.path.exists(IMS_EXPORT_DIR):
        logging.debug("Does not exist: '%s'", IMS_EXPORT_DIR)
        return
    logging.error("Exists but is not a directory: '%s'", IMS_EXPORT_DIR)
    sys.exit(1)


def main():
    """ Main function """
    logfile=os.path.join(LOG_DIR, datetime.datetime.now().strftime("%Y%m%d%H%M%S.log"))
    print(f"Detailed logging will be recorded to: {logfile}")
    logger.configure_logging(filename=logfile)

    validate_export_dirs()

    folder_name, all_artifacts = get_artifacts_list_from_minio()
    local_dir_list = create_local_directories(logfile)
    local_dir_list.assign_artifacts(all_artifacts)
    local_dir_list.sync_from_minio(folder_name)

    logging.info(
        "After IMS import is complete, run '%s' to clean up the IMS data from the local disks",
        IMS_CLEANUP_SCRIPT_PATH)
    logging.info("Done!")

if __name__ == "__main__":
    main()
