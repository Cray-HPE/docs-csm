#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
Given a list of xnames, repeatedly query their status in CFS until none are in pending
status. Periodically print a summary of their statuses. Exit with RC 0 if all are in
configured status at the end. Otherwise exit with non-0 RC.
"""

import argparse
import datetime
import sys
import time

from typing import List, Set

from python_lib import cfs
from python_lib.types import JsonDict


def datestr(msg: str) -> str:
    """
    Return the string with a timestamp prepended    
    """
    return datetime.datetime.now().strftime("%Y%m%d%H%M%S ") + msg


def print_stderr(msg: str) -> None:
    """
    Outputs the specified message to stderr
    """
    sys.stderr.write(datestr(f"{msg}\n"))


def print_err(msg: str) -> None:
    """
    Prepends "ERROR: " and outputs the specified message to stderr
    """
    print_stderr(f"ERROR: {msg}")


def err_exit(msg: str) -> None:
    """
    Print an error message and exit with RC 1
    """
    print_err(msg)
    sys.exit(1)


def print_datestr(msg: str) -> None:
    """
    Print the string with a timestamp prepended
    """
    print(datestr(msg))


def get_comp_status_map(id_list: List[str]) -> JsonDict:
    """
    Query CFS for the specified components and return a mapping from the component names to
    their config status
    """
    return {
        comp["id"]: comp["configurationStatus"] for comp in cfs.list_components(id_list=id_list) }


class ComponentStatus:
    """
    For a specified list of components, a mapping from their IDs to their current CFS
    configuration status
    """

    def __init__(self, id_list: List[str]):
        self.id_list = list(set(id_list))
        self.comp_status_map = get_comp_status_map(self.id_list)
        if self.missing_comps:
            err_exit(f"At least one component not found in CFS: {self.missing_comps}")
        for comp, stat in self.comp_status_map.items():
            print_datestr(f"CFS component {comp} has configuration status '{stat}'")

    @property
    def missing_comps(self) -> Set[str]:
        """
        Return a set of any component IDs that were in our initial set but not found in CFS.
        """
        return set(self.id_list).difference(self.comp_status_map)

    def update(self) -> None:
        """
        Query CFS to update our ID -> status map.
        Report on any IDs whose status have changed.
        """
        new_cs_map = get_comp_status_map(self.id_list)
        for comp, stat in new_cs_map.items():
            if self.comp_status_map[comp] != stat:
                print_datestr(f"CFS component {comp} now has configuration status '{stat}'")
        self.comp_status_map = new_cs_map
        if self.missing_comps:
            err_exit(f"At least one component not found in CFS: {self.missing_comps}")

    def comps_in_status(self, status: str) -> List[str]:
        """
        Return a list of components with the specified configuration status
        """
        return [
            comp for (comp, compstatus) in self.comp_status_map.items() if compstatus == status ]

    @property
    def pending(self) -> List[str]:
        """
        Shortcut to list components with pending status
        """
        return self.comps_in_status("pending")

    @property
    def all_statuses(self) -> List[str]:
        """
        A list of all component statuses
        """
        return list(set(self.comp_status_map.values()))

    def print_summary_by_status(self):
        """
        Print the components grouped by their status
        """
        print_datestr("Summary of CFS components by configuration status")
        for status in self.all_statuses:
            print_datestr(f"{status}: " + " ".join(self.comps_in_status(status)))

    @property
    def done(self) -> bool:
        """
        If any components have pending status, return False.
        Otherwise, print a summary of all components and return True.
        """
        if self.pending:
            return False
        self.print_summary_by_status()
        return True

    @property
    def success(self) -> bool:
        """
        Return True if all components have configured status.
        Return False otherwise.
        """
        return self.all_statuses == ["configured"]


def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    <component xname 1> [<comp xname 2>] ...
    """
    parser = argparse.ArgumentParser(
        description="Monitors CFS status of components until none are pending")
    parser.add_argument("cfs_component", nargs='+', help="CFS component to monitor")
    parsed_args = parser.parse_args()

    print_datestr("Querying CFS for component statuses")
    comp_status = ComponentStatus(parsed_args.cfs_component)
    count=0
    while not comp_status.done:
        if count % 10 == 0:
            num_pending = len(comp_status.pending)
            pending_list_str = " ".join(comp_status.pending)
            print_datestr(f"Number of CFS components still 'pending' is {num_pending}:"
                          f" {pending_list_str}")
        time.sleep(1)
        count+=1
        comp_status.update()
    if not comp_status.success:
        err_exit("Not all components successfully configured")
    print_datestr("SUCCESS")


if __name__ == '__main__':
    main()
