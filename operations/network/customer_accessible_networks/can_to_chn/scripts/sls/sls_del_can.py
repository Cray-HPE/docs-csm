#!/usr/bin/env python3
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
"""Upgrade an SLS file from using the CAN to the CHN idempotently."""
import json
import sys

import click

from csm_can_to_chn.sls_updates import delete_can_network
from sls_utils.Managers import NetworkManager


help = "Delete CAN entries from SLS."


@click.command(help=help)
@click.option(
    "--sls-input-file",
    required=True,
    help="Input SLS JSON file",
    type=click.File("r"),
)
@click.option(
    "--sls-output-file",
    help="Upgraded SLS JSON file name",
    type=click.File("w"),
    default="migrated_sls_file.json",
)
@click.pass_context
def main(
    ctx,
    sls_input_file,
    sls_output_file,
):
    """Upgrade an SLS file from using the CAN to the CHN.

    Args:
        ctx: Click context
        sls_input_file (str): Name of the SLS input file
        sls_output_file (str): Name of the updated SLS output file
    """
    click.confirm(
        "\n  You are deleting the CAN network data structure from SLS.\n  This script should only be used when upgrading from the CAN to the CHN.\n  Do you want to continue?",
        abort=True,
    )
    click.secho("Loading SLS JSON file.", fg="bright_white")
    try:
        sls_json = json.load(sls_input_file)
    except (json.JSONDecodeError, UnicodeDecodeError):
        click.secho(
            f"The file {sls_input_file.name} is not valid JSON.",
            fg="red",
        )
        sys.exit(1)

    click.secho(
        "Extracting existing Networks from SLS file and schema validating.",
        fg="bright_white",
    )
    networks = NetworkManager(sls_json["Networks"])
    #

    delete_can_network(networks)

    if sls_output_file:
        sls_json.pop("Networks")
        sls_json.update({"Networks": networks.to_sls()})
        new_json = json.dumps(sls_json, indent=2, sort_keys=True)
        click.echo(new_json, file=sls_output_file)


if __name__ == "__main__":
    main()
