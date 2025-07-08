#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
from pyscripts.commands.test_nmn_isolation import test_nmn_isolation
import logging
import click
import os

@click.command("test_nmn_isolation", short_help="Tests the isolation of external SSH access between the NMN Mountain Cabinets.")
@click.option(
    "--networks",
    type=click.Choice(["nmn", "nmn_mtn"], case_sensitive=False),
    multiple=True,
    default=["nmn", "nmn_mtn"],
    help="What networks to test with. Defaults: ('nmn', 'nmn_mtn')"
)
@pass_environment
def cli(ctx, networks):
    test_nmn_isolation.start_test()

