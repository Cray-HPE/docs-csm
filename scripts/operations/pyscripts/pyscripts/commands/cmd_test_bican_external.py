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

from pyscripts.cli import pass_environment
from pyscripts.commands.test_bican_external import test_bican_external
import logging
import click
import os


@click.command("test_bican_external", short_help="Tests the isolation of external SSH access across networks in CAN-toggled or CHN-toggled environments.")
@click.option(
    "--system-domain", prompt=True,
    default=lambda: os.environ.get("SYSTEM_DOMAIN", ""),
    help="What is the system domain you want to test? E.g. eniac.dev.cray.com"
)
@click.option(
    "--admin-client-secret", prompt=True,
    default=lambda: os.environ.get("ADMIN_CLIENT_SECRET", ""),
    help="What is the admin client secret? You can retrieve it from within the network by running the command:\n kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d'"
)
@click.option(
    "--to-types",
    type=click.Choice(["ncn_master", "ncn_worker", "ncn_storage", "cn", "uan", "spine_switch", "leaf_switch", "leaf_BMC", "CDU"], case_sensitive=False),
    multiple=True,
    default=["ncn_master", "spine_switch"],
    help="What types of nodes to test SSH access to. Defaults: ('ncn_master', 'spine_switch')"
)
@click.option(
    "--networks",
    type=click.Choice(["can", "chn", "cmn", "nmn", "nmnlb", "hmn", "hmnlb"], case_sensitive=False),
    multiple=True,
    default=["can", "chn", "cmn", "nmn", "nmnlb", "hmn", "hmnlb"],
    help="What networks to test with. Defaults: ('can', 'chn', 'cmn', 'nmn', 'nmnlb', 'hmn', 'hmnlb')"
)
@pass_environment
def cli(ctx, system_domain, admin_client_secret, to_types, networks):
    print(f"Testing external access to node types {to_types} on networks {networks}.")
    test_bican_external.start_test(system_domain, admin_client_secret, to_types, networks)
