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

"""
Module to provide BOS CLI functions
"""

import json
import subprocess
import tempfile

from typing import List

from .bos import BosError, BosOptions
from .bos_session_templates import BosSessionTemplate

class BosCliError(BosError):
    pass

def create_session_template(session_template: BosSessionTemplate, bos_version: int) -> None:
    """
    Wrapper for calling the CLI to create the specified BOS session template using the
    specified BOS version.
    Returns nothing.
    Raises BosCliError on error.
    """
    template_name = session_template["name"]
    template_to_create = session_template.copy()
    # Delete the name field (since it is specified on the command line of the create command)
    del template_to_create["name"]

    # Write template to a temporary file and create the record
    with tempfile.NamedTemporaryFile(mode="wt", suffix=".json", prefix="session_template") as tmp:
        json.dump(template_to_create, tmp)
        # Make sure the data has been written to the file so the CLI command can read it.
        tmp.flush()
        if bos_version == 1:
            create_command = ["cray", "bos", f"v{bos_version}", "sessiontemplate", "create",
                              "--file", tmp.name, "--name", template_name, "--format", "json"]
        else:
            create_command = ["cray", "bos", f"v{bos_version}", "sessiontemplates", "create",
                              "--file", tmp.name, template_name, "--format", "json"]
        try:
            subprocess.run(create_command, stdout=subprocess.PIPE, check=True)
        except subprocess.CalledProcessError as exc:
            raise BosCliError(f"Failed to create template '{template_name}': {exc}") from exc

def delete_session_template(template_name: str) -> None:
    """
    Wrapper for calling the CLI to delete the specified BOS session template.
    Uses BOS v2 since the version makes no difference to the results in this case.
    Returns nothing.
    Raises BosCliError on error.
    """
    delete_command = ["cray", "bos", "v2", "sessiontemplates", "delete", template_name]
    try:
        subprocess.run(delete_command, stdout=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to delete template '{template_name}': {exc}") from exc

def get_session_template(template_name: str) -> BosSessionTemplate:
    """
    Wrapper for calling the CLI to describe the specified BOS session template.
    Uses BOS v2 since the version makes no difference to the results in this case (despite
    what the API spec says).
    Returns the session template.
    Raises BosCliError on error.
    """
    get_command = ["cray", "bos", "v2", "sessiontemplates", "describe", template_name,
                   "--format", "json"]
    try:
        proc = subprocess.run(get_command, stdout=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to get template '{template_name}': {exc}") from exc
    return json.loads(proc.stdout)

def list_options() -> BosOptions:
    """
    Wrapper for calling the CLI to list the BOS options.
    Returns the dict of BOS options.
    Raises BosCliError on error.
    """
    list_command = "cray bos v2 options list --format json"
    try:
        proc = subprocess.run(list_command.split(), stdout=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to list options: {exc}") from exc
    return json.loads(proc.stdout)

def list_session_templates() -> List[BosSessionTemplate]:
    """
    Wrapper for calling the CLI to list all BOS session templates.
    Uses BOS v2 since the version makes no difference to the results in this case (despite
    what the API spec says).
    Returns the list.
    Raises BosCliError on error.
    """
    list_command = "cray bos v2 sessiontemplates list --format json"
    try:
        proc = subprocess.run(list_command.split(), stdout=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to list templates: {exc}") from exc
    return json.loads(proc.stdout)
