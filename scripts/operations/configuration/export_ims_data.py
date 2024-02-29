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
Export IMS data (and optionally linked S3 artifacts) to a tar archive.
"""

import argparse
import datetime
import logging
import os
import sys

from python_lib import args
from python_lib import common
from python_lib import ims_import_export
from python_lib import logger

LOG_DIR = "/var/log/export_ims_data"
os.makedirs(LOG_DIR, exist_ok=True)


def parse_args() -> argparse.Namespace:
    """
    Parses command-line arguments
    """
    parser = argparse.ArgumentParser()

    parser.add_argument('--estimate-size',  action='store_true',
                        help="Instead of performing an export, show the estimated total size of "
                        "the exported data. Because of how IMS images are stored in S3, this will "
                        "involve temporarily downloading some number of artifacts from S3.")

    parser.add_argument('--ignore-running-jobs', action='store_true',
                        help="Do not abort if there are IMS jobs in progress")

    parser.add_argument(
        '--include-deleted', action='store_true',
        help="Include deleted IMS recipe and image records (not included by default)"
    )

    parser.add_argument(
        '--exclude-links-from-bos', action='store_true',
        help="Exclude S3 artifacts found in BOS session templates (included by default, unless "
        "--exclude-linked-artifacts is specified)."
    )

    parser.add_argument(
        '--exclude-links-from-bss', action='store_true',
        help="Exclude S3 artifacts found in BSS boot parameters (included by default, unless "
        "--exclude-linked-artifacts is specified)."
    )

    parser.add_argument(
        '--exclude-links-from-product-catalog', action='store_true',
        help="Exclude S3 artifacts found in Cray product catalog (included by default, unless "
        "--exclude-linked-artifacts is specified)."
    )

    parser.add_argument(
        '--exclude-linked-artifacts', action='store_true',
        help="Exclude linked recipe and image S3 artifacts (included by default). This implies --no-tar"
    )

    parser.add_argument(
        '--no-tar', action='store_true',
        help=("Do not create a tar archive of the exported data. This is the default behavior if "
              "--exclude-linked-artifacts is specified. Otherwise, by default the individual export files are deleted "
              "after being added to a tar archive")
    )

    parser.add_argument(
        'target_directory', nargs='?', default=os.getcwd(), type=args.readable_directory,
        help='Directory in which to create IMS export (defaults to current directory)'
    )

    return parser.parse_args()

def main():
    """ Main function """
    parsed_args = parse_args()
    logfile=os.path.join(LOG_DIR, datetime.datetime.now().strftime("%Y%m%d%H%M%S.log"))
    print(f"Detailed logging will be recorded to: {logfile}")
    logger.configure_logging(filename=logfile)

    try:
        export_options = ims_import_export.ExportOptions(
            ignore_running_jobs=parsed_args.ignore_running_jobs,
            include_deleted=parsed_args.include_deleted,
            exclude_linked_artifacts=parsed_args.exclude_linked_artifacts,
            no_tar=parsed_args.no_tar,
            target_directory=parsed_args.target_directory,
            exclude_links_from_bos=parsed_args.exclude_links_from_bos,
            exclude_links_from_bss=parsed_args.exclude_links_from_bss,
            exclude_links_from_product_catalog=parsed_args.exclude_links_from_product_catalog)
        if parsed_args.estimate_size:
            ims_import_export.estimate_export_size(export_options)
            return
        ims_import_export.do_export(export_options)
        logging.info('DONE!')
        return
    except ims_import_export.ImsJobsRunning:
        logging.info("Wait until jobs are completed or see script usage for override option")
        logging.error("Aborted due to incomplete jobs")
    except common.ScriptException as exc:
        logging.error(exc)
    sys.exit(1)


if __name__ == "__main__":
    main()
