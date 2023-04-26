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
"""Shared Python function library: argument parsing"""

import argparse
import getpass
import logging
import os

from typing import Callable, List


TEXT_FILE_TYPE = argparse.FileType('rt', encoding="utf-8")


def readable_directory(directory_string: str) -> str:
    """
    Validates that the string is the path to a readable directory.
    If so, returns the directory string.
    Raises an ArgumentTypeError if not.
    """
    if not os.path.exists(directory_string):
        raise argparse.ArgumentTypeError(f"Directory does not exist: '{directory_string}'")
    if not os.path.isdir(directory_string):
        raise argparse.ArgumentTypeError(f"Exists but is not a directory: '{directory_string}'")
    if not os.access(directory_string, os.R_OK):
        raise argparse.ArgumentTypeError(f"Directory exists but is not readable: '{directory_string}'")
    return directory_string


def readable_file(filepath_string: str) -> str:
    """
    Validates that the string is the path to a readable file.
    If so, returns the filepath string.
    Raises an ArgumentTypeError if not.
    """
    if not os.path.exists(filepath_string):
        raise argparse.ArgumentTypeError(f"File does not exist: '{filepath_string}'")
    if not os.path.isfile(filepath_string):
        raise argparse.ArgumentTypeError(f"Exists but is not a regular file: '{filepath_string}'")
    if not os.access(filepath_string, os.R_OK):
        raise argparse.ArgumentTypeError(f"File exists but is not readable: '{filepath_string}'")
    return filepath_string


def get_text_file_contents(file_name: str,
                           value_validator: Callable = None) -> str:
    """
    Reads in the contents of the specified file as a string.

    If value_validator is set, it is called with the file contents string as the only argument.
    The return of the call is not examined -- the expectation is that the call will raise an
    ArgumentTypeError if there is a problem.

    Returns the file contents string if there are no errors.
    """
    # Use the built-in argparse FileType to open the file for reading.
    # This will automatically raise appropriate errors if there are any issues.
    file_contents = TEXT_FILE_TYPE(file_name).read()

    if value_validator is not None:
        try:
            value_validator(file_contents)
        except argparse.ArgumentTypeError as exc:
            raise argparse.ArgumentTypeError(
                f"Contents of '{file_name}' file failed validation: {exc}") from exc

    return file_contents


def get_env_var_value(env_var_name: str,
                      value_validator: Callable = None,
                      unset_ok: bool = False) -> str:
    """
    Looks up the value of the specified environment variable.

    If unset_ok is False and the variable is not set, an ArgumentTypeError is raised.

    NOTE that the variable may be set to an empty string, which is not the same as being unset.
    If that condition needs to be caught, then the value_validator parameter must be used.

    If value_validator is set, it is called with the variable value as the only argument.
    The return of the call is not examined -- the expectation is that the call will raise an
    ArgumentTypeError if there is a problem.

    If there are no errors, the value of the variable is returned (or an empty string, if
    the variable is unset and unset_ok is True).
    """
    env_var_value = os.getenv(env_var_name)
    if env_var_value is None:
        msg = f"Environment variable {env_var_name} is not set"
        if unset_ok:
            logging.debug(f"{msg}; unset_ok is True")
            env_var_value = ""
        else:
            logging.error(msg)
            raise argparse.ArgumentTypeError(msg)

    if value_validator is not None:
        try:
            value_validator(env_var_value)
        except argparse.ArgumentTypeError as exc:
            raise argparse.ArgumentTypeError(
                f"Value of environment variable {env_var_name} failed validation: {exc}") from exc

    return env_var_value


def validate_string(string_to_validate: str,
                    min_length: int = None,
                    max_length: int = None,
                    required_prefix: str = None) -> None:
    """
    If the specified string fails to meet any of the requirements, raise an
    argparse.ArgumentTypeError.
    """
    string_length = len(string_to_validate)

    if min_length is not None and string_length < min_length:
        raise argparse.ArgumentTypeError(
            f"Length {string_length} is less than minimum permitted length {min_length}")

    if max_length is not None and string_length > max_length:
        raise argparse.ArgumentTypeError(
            f"Length {string_length} is greater than maximum permitted length {max_length}")

    if required_prefix is not None and string_to_validate.find(required_prefix) != 0:
        raise argparse.ArgumentTypeError(
            f"Does not begin with required prefix: '{required_prefix}'")


class PasswordPromptAction(argparse.Action):
    """
    Custom argparse action to prompt user for a password, have them re-enter it to verify,
    and then validate that it meets the minimum and maximum length requirements (if any).
    """

    def __init__(self, option_strings: List, dest: str, nargs=0,
                 min_length: int = None, max_length: int = None, **kwargs):
        """
        Initialize the custom action, storing the length requirements for later use
        """
        if nargs != 0:
            raise ValueError("nargs must be 0")
        self.min_length, self.max_length = min_length, max_length
        super().__init__(option_strings, dest, nargs=nargs, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        """
        Prompt the user for the password, making sure that it meets the length requirements (if any)
        and that it is entered correctly a second time
        """
        logging.debug("Prompting user for password")
        while True:
            pw_text = getpass.getpass("Enter desired password: ")
            try:
                validate_string(pw_text, min_length=self.min_length,
                                max_length=self.max_length)
            except argparse.ArgumentTypeError as exc:
                logging.error(exc)
                continue
            if pw_text == getpass.getpass("Verify password: "):
                break
            logging.error("Passwords do not match. Please try again.")
        setattr(namespace, self.dest, pw_text)
