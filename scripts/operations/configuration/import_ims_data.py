#! /usr/bin/env python3
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

"""
Import IMS data (and optionally linked S3 artifacts) from a tar archive.
"""

import argparse
import datetime
import logging
import os
import shutil
import sys

from python_lib import args
from python_lib import common
from python_lib import ims_import_export
from python_lib import logger


LOG_DIR = "/var/log/import_ims_data"
os.makedirs(LOG_DIR, exist_ok=True)


def parse_args() -> argparse.Namespace:
    """
    Parses command-line arguments

    Returns the parsed command line arguments
    """
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-b', '--backup-dir', type=args.readable_directory, default=os.getcwd(),
        help='Directory in which to make backup of IMS data before doing import'
    )

    parser.add_argument('-c', '--cleanup', type=str, default='on_success',
        choices=['never', 'on_success'],
        help=('When should the script delete the extracted tarfile directory '
              '(this has no effect if -d argument is specified)')
    )

    parser.add_argument('--ignore-running-jobs', action='store_true',
                        help=('Perform update/overwrite import even if there are IMS jobs in progress '
                              '(this flag has no effect on add imports)'))

    parser.add_argument(
        '-w', '--work-dir', type=args.readable_directory, default=os.getcwd(),
        help='Directory in which to extract the IMS archive'
    )

    import_source = parser.add_mutually_exclusive_group(required=True)
    import_source.add_argument('-d', dest="expanded_tarfile_directory", type=args.readable_directory,
                               help="Directory of extracted IMS export tar archive")
    import_source.add_argument('-f', dest="tarfile_path", type=lambda s: args.readable_file_with_ext(s, '.tar'),
                               help="Path to IMS export tar archive")

    parser.add_argument('import_type', type=str, choices=list(ims_import_export.IMPORT_FUNCTIONS),
                        help=". ".join([ f"{itype}: {ifunc.__doc__}"
                                         for itype, ifunc in ims_import_export.IMPORT_FUNCTIONS.items() ]))

    return parser.parse_args()


class ImsImportBaseError(ims_import_export.ImsImportExportError):
    """
    Base exception class for the script
    """


def do_import(script_args: argparse.Namespace) -> None:
    """
    Do the import. Raise an exception if there is trouble
    """
    # Try some Kubernetes and other checks up front because if it doesn't work, we'd rather know that before
    # we clear anything in IMS/S3
    ims_import_export.get_ims_pod_name()
    common.validate_file_readable(ims_import_export.ImsPodImportToolPath)

    tarfile_dir = script_args.expanded_tarfile_directory
    if tarfile_dir is None:
        # This means we need to expand it
        tarfile_dir = ims_import_export.expand_tarfile(script_args.tarfile_path, script_args.work_dir)

    exported_data = ims_import_export.ExportedData.load_from_directory(tarfile_dir)

    # Backup current IMS data
    logging.info("Performing pre-import backup of IMS data to directory '%s'", script_args.backup_dir)
    current_data, _ = ims_import_export.do_export(ims_import_export.ExportOptions(
                        ignore_running_jobs=script_args.ignore_running_jobs,
                        include_deleted=True,
                        exclude_linked_artifacts=True,
                        no_tar=True,
                        target_directory=script_args.backup_dir))

    # We pass ignore_running_jobs = True here because we have already checked this above, if applicable
    import_options = ims_import_export.ImportOptions(tarfile_dir=tarfile_dir,
                                              ignore_running_jobs=True,
                                              current_ims_data=current_data.ims_data,
                                              exported_data=exported_data)

    # Do import
    ims_import_export.IMPORT_FUNCTIONS[script_args.import_type](import_options)

    # Cleanup, if applicable
    if script_args.expanded_tarfile_directory is None and script_args.cleanup == 'on_success':
        # Delete the contents of the extracted tarfile directory created earlier
        logging.info("Script successful: removing directory '%s'", tarfile_dir)
        shutil.rmtree(tarfile_dir)


def main():
    """ Main function """
    script_args = parse_args()

    logfile=os.path.join(LOG_DIR, datetime.datetime.now().strftime("%Y%m%d%H%M%S.log"))
    print(f"Detailed logging will be recorded to: {logfile}")
    logger.configure_logging(filename=logfile)
    logging.debug("Command-line arguments: %s", sys.argv)
    logging.debug("Parsed arguments: %s", script_args)

    try:
        do_import(script_args)
        logging.info("DONE!")
        return
    except common.InsufficientSpace as exc:
        logging.info("An alternate location to use for tarfile expansion can be specified with the '--work-dir' argument")
        logging.error(exc)
    except ims_import_export.ImsJobsRunning:
        logging.info("Wait until jobs are completed or see script usage for override option")
        logging.error("Aborted import due to incomplete jobs")
    except common.ScriptException as exc:
        logging.error(exc)

    sys.exit(1)

if __name__ == "__main__":
    main()
