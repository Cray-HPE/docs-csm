#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
"""Shared Python function library: basic functions"""

import logging
import sys
import traceback


class ScriptException(Exception):
    """
    Generic script exception class
    """


def log_error_raise_exception(msg: str, parent_exception: Exception = None) -> None:
    """
    1) If a parent exception is passed in, make a debug log entry with its stack trace.
    2) Log an error with the specified message.
    3) Raise a ScriptException with the specified message (from the parent exception, if
       specified)
    """
    if parent_exception is not None:
        logging.debug(traceback.format_exc())
    logging.error(msg)
    if parent_exception is None:
        raise ScriptException(msg)
    raise ScriptException(msg) from parent_exception


def print_err_exit(msg: str) -> None:
    """
    Print the specified error message to stderr and exit the script with return code 1
    """
    sys.stderr.write(f"ERROR: {msg}\n")
    sys.stderr.flush()
    sys.exit(1)


def read_file(filename: str, min_length: int = 4) -> str:
    """
    Reads contents of text file, verifies it is more than the specified length,
    and returns it as a string.
    """
    logging.info(f"Reading in file '{filename}'")
    try:
        with open(filename, "rt", encoding="utf-8") as textfile:
            contents = textfile.read()
    except FileNotFoundError:
        log_error_raise_exception(f"File '{filename}' does not exist")
    if min_length > 0:
        file_len = len(contents)
        if file_len < min_length:
            log_error_raise_exception(
                f"File '{filename}' only contains {file_len} characters")
    return contents
