#
# MIT License
#
# (C) Copyright 2022-2024 Hewlett Packard Enterprise Development LP
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
import os
import shutil
import subprocess
import sys
import time
import traceback

from contextlib import contextmanager
from typing import Any, List, Union

WAIT_SECONDS_BETWEEN_COMMAND_RETRIES=2

class ScriptException(Exception):
    """
    Generic script exception class
    """

class InsufficientSpace(ScriptException):
    """
    To indicate when an operation is failing because not enough disk space is available
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


def print_stderr(msg: str) -> None:
    """
    Outputs the specified message to stderr
    """
    sys.stderr.write(f"{msg}\n")


def print_err(msg: str) -> None:
    """
    Prepends "ERROR: " and outputs the specified message to stderr
    """
    print_stderr(f"ERROR: {msg}")


def print_warn(msg: str) -> None:
    """
    Prepends "WARNING: " and outputs the specified message to stderr
    """
    print_stderr(f"WARNING: {msg}")


def print_err_exit(msg: str) -> None:
    """
    Print the specified error message to stderr and exit the script with return code 1
    """
    print_err(msg)
    sys.stderr.flush()
    sys.exit(1)


def read_file(filename: str, min_length: int = 4) -> str:
    """
    Reads contents of text file, verifies it is more than the specified length,
    and returns it as a string.
    """
    logging.info("Reading in file '{%s}'", filename)
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


# https://dev.to/teckert/changing-directory-with-a-python-context-manager-2bj8
@contextmanager
def set_directory(path: str):
    """Sets the cwd within the context

    Args:
        path (Path): The path to the cwd

    Yields:
        None
    """

    origin = os.getcwd()
    try:
        os.chdir(path)
        yield
    finally:
        os.chdir(origin)


# https://stackoverflow.com/a/15485265
def sizeof_fmt(num):
    """
    Given a number of bytes, returns a human-friendly string
    representation of the size.
    """
    suffix="bytes"
    for unit in ("", "kilo", "mega", "giga", "tera"):
        if abs(num) < 1024.0:
            return f"{num:3.3f} {unit}{suffix}"
        num /= 1024.0
    return f"{num:.3f} peta{suffix}"


def expected_format(obj: Any, obj_desc: str, expected_type: type) -> None:
    """
    Validates that obj is of the expected type. Otherwise an exception is raised.
    obj_desc is a string to describe the object in the exception.
    """
    if isinstance(obj, expected_type):
        return
    msg = (f"{obj_desc} has unexpected format. Expected type={expected_type.__name__}, "
           f"actual type={type(obj).__name__})")
    logging.error(msg)
    raise ScriptException(msg)


def verify_free_space_in_dir(dirpath: str, min_bytes: int) -> None:
    """
    Raise InsufficientSpace if specified directory does not have at least min_bytes of free space
    """
    free_bytes = shutil.disk_usage(dirpath).free
    if free_bytes >= min_bytes:
        return

    msg = (f"Only {sizeof_fmt(free_bytes)} free space in directory '{dirpath}'. "
           f"An additional {sizeof_fmt(min_bytes-free_bytes)} is required.")
    logging.error(msg)
    raise InsufficientSpace(msg)


def validate_directory_exists(dirpath: str) -> None:
    """
    Raises ScriptException if specified directory does not exists or is not a regular directory
    """
    if not os.path.exists(dirpath):
        raise ScriptException(f"Directory does not exist: '{dirpath}'")
    if not os.path.isdir(dirpath):
        raise ScriptException(f"Exists but is not a directory: '{dirpath}'")


def validate_directory_readable(dirpath: str) -> None:
    """
    First calls validate_directory_exists.
    Then raises ScriptException if specified directory is not readable
    """
    validate_directory_exists(dirpath)
    if not os.access(dirpath, os.R_OK):
        raise ScriptException(f"Directory exists but is not readable: '{dirpath}'")


def validate_file_exists(filepath: str) -> None:
    """
    Raises ScriptException if specified file does not exists or is not a regular file
    """
    if not os.path.exists(filepath):
        raise ScriptException(f"File does not exist: '{filepath}'")
    if not os.path.isfile(filepath):
        raise ScriptException(f"Exists but is not a regular file: '{filepath}'")


def validate_file_readable(filepath: str) -> None:
    """
    First calls validate_file_exists.
    Then raises ScriptException if specified file is not readable
    """
    validate_file_exists(filepath)
    if not os.access(filepath, os.R_OK):
        raise ScriptException(f"File exists but is not readable: '{filepath}'")

def run_command(command: List[str], num_retries: int=0, timeout: Union[int, None]=None) -> bytes:
    """
    Runs the specified command and returns the output.
    If num_retries is non-0, if the command fails, it will be retried up to the
    specified number of times.
    """
    while True:
        logging.debug(command)
        try:
            cmd_result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
            logging.debug("stdout: %s", cmd_result.stdout)
            logging.debug("stderr: %s", cmd_result.stderr)
            return cmd_result.stdout
        except subprocess.CalledProcessError as exc:
            logging.warning("Command failed with return code %d: %s", exc.returncode, exc.cmd)
            logging.debug("stdout: %s", exc.stdout)
            logging.debug("stderr: %s", exc.stderr)
            if num_retries == 0:
                raise exc
        except subprocess.TimeoutExpired as exc:
            logging.warning("Command did not complete after %d seconds: %s", exc.timeout, exc.cmd)
            logging.debug("stdout: %s", exc.stdout)
            logging.debug("stderr: %s", exc.stderr)
            if num_retries == 0:
                raise exc
        logging.debug("Retrying command after %d seconds (%d retries remaining)", WAIT_SECONDS_BETWEEN_COMMAND_RETRIES, num_retries)
        time.sleep(WAIT_SECONDS_BETWEEN_COMMAND_RETRIES)
        num_retries-=1
