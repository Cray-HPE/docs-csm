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
"""Delete CAN entries from BSS, this is used for CHN upgrade."""
import json
import sys
import click
import ipaddress


help = """Remove CAN entries from BSS, this is used for CHN upgrade"""


@click.command(help=help)
@click.option(
    "--bss-input-file",
    required=True,
    help="BSS Boot Parameters JSON file",
    type=click.File("r"),
)
@click.option(
    "--bss-output-file",
    help="Upgraded BSS Boot Parameters file name",
    type=click.File("w"),
    default="migrated_bss_bootparameters.json",
)
@click.pass_context
def main(
    ctx,
    bss_input_file,
    bss_output_file,
):
    """Upgrade a BSS file to use with CHN

    Args:
        ctx: Click context
        bss_input_file (str): Name of the BSS Boot Parameters input file
        bss_output_file (str): Name of the updated BSS Boot Parameters output file

    """

    try:
        bss_bootparameters = json.load(bss_input_file)
    except (json.JSONDecodeError, UnicodeDecodeError):
        click.secho(
            f"The file {bss_input_file.name} is not valid JSON.",
            fg="red",
        )
        sys.exit(1)
    for host in bss_bootparameters:
        if host["cloud-init"]["meta-data"] is not None:
            try:
                ipam = host["cloud-init"]["meta-data"]["ipam"]
                for net in list(ipam.keys()):
                    if "can" in net:
                        can_ip = ipaddress.IPv4Interface(ipam["can"]["ip"])
                        del ipam[net]
                        # remove CAN NTP entry if it exists
                        if host["cloud-init"]["user-data"]["ntp"]["allow"] is not None:
                            ntp_allow = host["cloud-init"]["user-data"]["ntp"]["allow"]
                            for ip in ntp_allow:
                                if ip == str(can_ip) or ip == str(can_ip.network):
                                    ntp_allow.remove(ip)
            except KeyError:
                pass
            try:
                host_records = host["cloud-init"]["meta-data"]["host_records"]
                for host_record in host_records:
                    for alias in host_record.get("aliases"):
                        if "can" in alias:
                            host_records.remove(host_record)
            except KeyError:
                pass

    if bss_output_file:
        new_bss = json.dumps(bss_bootparameters, indent=2, sort_keys=False)
        click.echo(new_bss, file=bss_output_file)


if __name__ == "__main__":
    main()
