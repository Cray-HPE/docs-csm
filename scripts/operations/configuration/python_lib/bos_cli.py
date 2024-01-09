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

"""
Module to provide BOS CLI functions
"""

import json
import os
import subprocess
import tempfile

from typing import List

from .api_requests import get_full_api_token
from .bos import BosError, BosOptions, BosSessionTemplate, BosSessionTemplateUniqueId, \
                 Tenant, append_tenant


class BosCliError(BosError):
    pass


TENANT_CLI_CONFIG_TEMPLATE = ('[core]\nhostname = "https://api-gw-service-nmn.local"\n'
                              'tenant = "{tenant}"\n')

CLI_AUTH_TOKEN = None

def get_cli_auth_token_if_needed() -> None:
    """
    Sets the CLI_AUTH_TOKEN variable, if it has not already been set
    """
    global CLI_AUTH_TOKEN
    if CLI_AUTH_TOKEN is None:
        CLI_AUTH_TOKEN, _ = get_full_api_token()


def add_env_var_to_subprocess_run_kwargs(var_name: str, var_value: str, subprocess_run_kwargs: dict) -> None:
    """
    Updates in place the subprocess_run_kwargs dict, with env argument appropriately added or updated
    """
    if "env" not in subprocess_run_kwargs or subprocess_run_kwargs["env"] is None:
        # Either the env kwarg is not currently specified, or it is being specified as None.
        # In either case, this means we should get a copy of the current environment
        # variables, because we need to add the new variable on top of them
        subprocess_run_kwargs["env"] = os.environ.copy()

    if not isinstance(subprocess_run_kwargs["env"], dict):
        # This should never be the case
        raise TypeError("env kwarg should be None or a dict, but it has type: "
                        f"{type(subprocess_run_kwargs['env'])}")

    subprocess_run_kwargs["env"][var_name] = var_value


def run_bos_cli_command(args: List[str], tenant: Tenant = None,
                        **subprocess_run_kwargs) -> subprocess.CompletedProcess:
    """
    Calls subprocess.run to execute "cray bos <args>" (with any specified kwargs passed along in
    the function call).
    If a non-empty, non-None tenant is specified, a temporary CLI config file is created to specify
    the tenant, and the CLI command is run with the CRAY_CONFIG environment variable pointing to it.
    The result of the subprocess.run call is returned.
    """
    if tenant:
        with tempfile.NamedTemporaryFile(mode="wt", suffix=".tmp", prefix="cray_cli_config") as tmp_config:
            tmp_config.write(TENANT_CLI_CONFIG_TEMPLATE.format(tenant=tenant))
            # Make sure the data has been written to the file so the CLI command can read it.
            tmp_config.flush()
            
            # We want to run the CLI command with the CRAY_CONFIG environment variable pointing to
            # this temporary file
            add_env_var_to_subprocess_run_kwargs("CRAY_CONFIG", tmp_config.name, subprocess_run_kwargs)

            # Now recursively call ourselves, but with tenant set to None
            return run_bos_cli_command(args=args, tenant=None, **subprocess_run_kwargs)

    get_cli_auth_token_if_needed()
    with tempfile.NamedTemporaryFile(mode="wt", suffix=".tmp", prefix="cray_cli_config_auth") as tmp_auth:
        tmp_auth.write(CLI_AUTH_TOKEN)
        # Make sure the data has been written to the file so the CLI command can read it.
        tmp_auth.flush()

        # We want to run the CLI command with the CRAY_CREDENTIALS environment variable pointing to
        # this temporary file
        add_env_var_to_subprocess_run_kwargs("CRAY_CREDENTIALS", tmp_auth.name, subprocess_run_kwargs)

        return subprocess.run([ "cray", "bos" ] + args, **subprocess_run_kwargs)


def create_session_template(session_template: BosSessionTemplate) -> None:
    """
    Wrapper for calling the CLI to create the specified BOS session template.
    BOS v2 is used unless the template is in v1 format.
    Returns nothing.
    Raises BosCliError on error.
    """
    bos_version = session_template.version
    name_tenant = session_template.name_tenant

    # Write template to a temporary file and create the record
    with tempfile.NamedTemporaryFile(mode="wt", suffix=".json", prefix="session_template") as tmp:
        json.dump(session_template.contents, tmp)
        # Make sure the data has been written to the file so the CLI command can read it.
        tmp.flush()
        if bos_version == 1:
            create_command = [f"v{bos_version}", "sessiontemplate", "create",
                              "--file", tmp.name, "--name", name_tenant.name, "--format", "json"]
        else:
            create_command = [f"v{bos_version}", "sessiontemplates", "create",
                              "--file", tmp.name, name_tenant.name, "--format", "json"]
        try:
            run_bos_cli_command(create_command, tenant=name_tenant.tenant, stdout=subprocess.PIPE,
                                check=True)
        except subprocess.CalledProcessError as exc:
            raise BosCliError(f"Failed to create template {name_tenant}: {exc}") from exc


def delete_session_template(template_id: BosSessionTemplateUniqueId) -> None:
    """
    Wrapper for calling the CLI to delete the specified BOS session template.
    Uses BOS v2 since the version makes no difference to the results in this case.
    Returns nothing.
    Raises BosCliError on error.
    """
    delete_command = ["v2", "sessiontemplates", "delete", template_id.name]
    try:
        run_bos_cli_command(delete_command, tenant=template_id.tenant, stdout=subprocess.PIPE,
                            check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to delete template {template_id}: {exc}") from exc


def get_session_template(template_id: BosSessionTemplateUniqueId) -> BosSessionTemplate:
    """
    Wrapper for calling the CLI to describe the specified BOS session template.
    Uses BOS v2 since the version makes no difference to the results in this case (despite
    what the API spec says).
    Returns the session template.
    Raises BosCliError on error.
    """
    get_command = ["v2", "sessiontemplates", "describe", template_id.name, "--format", "json"]
    try:
        proc = run_bos_cli_command(get_command, tenant=template_id.tenant, stdout=subprocess.PIPE,
                                   check=True)
    except subprocess.CalledProcessError as exc:
        raise BosCliError(f"Failed to get template {template_id}: {exc}") from exc
    return BosSessionTemplate(json.loads(proc.stdout))


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


def list_session_templates(tenant: Tenant = None) -> List[BosSessionTemplate]:
    """
    Wrapper for calling the CLI to list all BOS session templates.
    Uses BOS v2 since the version makes no difference to the results in this case (despite
    what the API spec says).
    Returns the list.
    Raises BosCliError on error.
    """
    list_command = "v2 sessiontemplates list --format json"
    try:
        proc = run_bos_cli_command(list_command.split(), tenant=tenant, stdout=subprocess.PIPE,
                                   check=True)
    except subprocess.CalledProcessError as exc:
        msg = append_tenant("Failed to list templates", tenant)
        raise BosCliError(f"{msg}: {exc}") from exc
    return [ BosSessionTemplate(template) for template in json.loads(proc.stdout) ]
