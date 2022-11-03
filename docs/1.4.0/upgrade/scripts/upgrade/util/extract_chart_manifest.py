#!/usr/bin/env python3
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

"""Extract a manifest for a specific chart from a specified CSM manifest file"""

import argparse
import os.path
import string
import sys
import yaml

legal_chart_name_characters = frozenset( string.ascii_lowercase + string.digits + "-" )

def valid_chart_name(s):
    if len(s) == 0:
        raise argparse.ArgumentTypeError("Chart name is blank")
    elif s[0] not in string.ascii_lowercase:
        raise argparse.ArgumentTypeError(f"Chart name must start with a lowercase letter. Invalid chart name: {s}")
    elif any(c not in legal_chart_name_characters for c in s):
        raise argparse.ArgumentTypeError(f"Chart name must consist of lowercase letters, digits, and hyphens. Invalid chart name: {s}")
    return s

def valid_dir(s):
    if len(s) == 0:
        raise argparse.ArgumentTypeError("Chart directory is blank")
    elif s[0] != "/":
        raise argparse.ArgumentTypeError(f"Chart directory must be absolute path. Invalid chart directory: {s}")
    elif not os.path.isdir(s):
        raise argparse.ArgumentTypeError(f"Chart directory does not exist: {s}")
    return s

def main(chart_name, source_file, chart_dir):
    manifest = yaml.safe_load(source_file)
    # Replace the current name with chart_name for the overall manifest
    manifest["metadata"]["name"] = chart_name

    # Replace the spec.sources.charts entry with one named "csm", pointing to the specified chart directory
    manifest["spec"]["sources"]["charts"] = [ { "name": "csm", "type": "directory", "location": chart_dir } ]

    # Create a new spec.charts list from the old one, with the following changes:
    # - remove any whose name do not match the specified chart name
    # - change the source to "csm"
    chartlist = list()
    for c in manifest["spec"]["charts"]:
        if c["name"] != chart_name:
            continue
        c["source"] = "csm"
        chartlist.append(c)
    if len(chartlist) == 0:
        print(f"ERROR: No entry for chart {chart_name} found in specified manifest file", file=sys.stderr)
        return 1

    # Replace the old chart list with our new one
    manifest["spec"]["charts"] = chartlist

    # Print the new manifest to stdout and exit
    print(yaml.dump(manifest))
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract a manifest for a specific chart from a specified CSM manifest file")
    parser.add_argument("--chart_dir", type=valid_dir, default=None, help="Full path to the directory containing Helm charts. Defaults to the ../helm from the specified manifest file directory.")
    parser.add_argument("chart_name", type=valid_chart_name, help="Name of the chart to extract from the manifest. For example: csm-config")
    parser.add_argument("csm_manifest_file", type=argparse.FileType('rt'), help="Full path and filename of the CSM manifest file to use as the source.")
    args = parser.parse_args()

    if args.chart_dir == None:
        # Set default value
        # First, determine directory containing csm_manifest_file
        manifest_dir = os.path.dirname(args.csm_manifest_file.name)
        
        # Default is to ../helm from that
        chart_dir = os.path.realpath(manifest_dir + "/../helm")

        if not os.path.isdir(chart_dir):
            print(f"ERROR: No chart directory specified and default chart directory does not exist: {chart_dir}", file=sys.stderr)
            sys.exit(1)
    else:
        chart_dir = args.chart_dir

    sys.exit(main(args.chart_name, args.csm_manifest_file, chart_dir))
