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
"""Shared Python function library: IMS import"""

from typing import NamedTuple

from .exceptions import ImsJobsRunning
from .exported_data import ExportedData
from .ims_data import ImsData


class ImportOptions(NamedTuple):
    tarfile_dir: str
    ignore_running_jobs: bool
    current_ims_data: ImsData
    exported_data: ExportedData

    def verify_no_running_jobs(self) -> None:
        """
        Returns immediately if ignore_running_jobs is True.

        Looks at all of the jobs in the current IMS data and raises an exception if they
        do not all have a status of error or success
        """
        if self.ignore_running_jobs:
            return
        if self.current_ims_data.running_jobs():
            raise ImsJobsRunning()
