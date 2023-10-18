#! /usr/bin/env python3
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

"""
Export IMS data (and optionally linked S3 artifacts) to a tar archive.
"""

import argparse
import logging
import os
import sys

from python_lib import args
from python_lib import common
from python_lib import ims_export
from python_lib import ims_import_export

LOGGER = logging.getLogger(__name__)
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
LOGGER.addHandler(ch)


def parse_args() -> argparse.Namespace:
    """
    Parses command-line arguments

    Returns a tuple: <log level>, <include_deleted>, <include_linked_artifacts>, <target_directory>
    """
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--log-level', type=str, default="INFO", choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        help='Set the logging level'
    )

    parser.add_argument('--ignore-running-jobs', action='store_true',
                        help=('Perform export even if there are IMS jobs in progress'))

    parser.add_argument(
        '--include-deleted', action='store_true',
        help="Include deleted IMS recipe and image records (not included by default)"
    )

    parser.add_argument(
        '--exclude-linked-artifacts', action='store_true',
        help="Exclude linked recipe and image S3 artifacts (included by default)"
    )

    parser.add_argument(
        'target_directory', nargs='?', default=os.getcwd(), type=args.readable_directory,
        help='Directory in which to create IMS export archive'
    )

    return parser.parse_args()


def main():
    """ Main function """
    parsed_args = parse_args()
    logging.basicConfig(level=parsed_args.log_level,
                        format='%(asctime)s %(levelname)-8s %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    try:
        ims_export.do_export(parsed_args.ignore_running_jobs, parsed_args.include_deleted,
                             parsed_args.exclude_linked_artifacts, parsed_args.target_directory)
    except ims_import_export.ImsJobsRunning:
        LOGGER.info("Wait until jobs are completed or see script usage for override option")
        common.print_err_exit("Aborted export due to incomplete jobs")
    except common.ScriptException as exc:
        common.print_err_exit(exc)
        # The above function should also end the script, but just in case
        sys.exit(1)
    LOGGER.info('DONE!')


if __name__ == "__main__":
    main()
