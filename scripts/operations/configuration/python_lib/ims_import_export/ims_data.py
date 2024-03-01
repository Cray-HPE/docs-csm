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
"""Shared Python function library: IMS import/export"""

import logging
from typing import List, NamedTuple, Union

from python_lib import ims
from python_lib.types import JsonDict

from .exceptions import ImsJobsRunning
from .ims_deleted_data import ImsDeletedData

class ImsData(NamedTuple):
    deleted: Union[None, ImsDeletedData]
    images: ims.ImsObjectMap
    jobs: ims.ImsObjectMap
    public_keys: ims.ImsObjectMap
    recipes: ims.ImsObjectMap

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, include_deleted: bool, ignore_running_jobs: bool = True) -> "ImsData":
        """
        Collects the information on the resources in IMS and returns an ImsData
        object populated with it.
        If ignore_running_jobs is False, then raise ImsJobsRunning exception if any IMS jobs are currently running.
        """
        logging.info("Loading data from IMS")
        logging.debug("Recording list of IMS jobs")
        jobs = ims.list_jobs()
        if not ignore_running_jobs:
            jobs_running = False
            for msg in get_running_jobs(jobs):
                jobs_running = True
                logging.error(msg)
            if jobs_running:
                raise ImsJobsRunning()
        logging.debug("Recording list of IMS images")
        images = ims.list_images()
        logging.debug("Recording list of IMS public keys")
        public_keys = ims.list_public_keys()
        logging.debug("Recording list of IMS recipes")
        recipes = ims.list_recipes()
        return ImsData(
            deleted=ImsDeletedData.load_from_system() if include_deleted else None,
            images=ims.ImsObjectMap.from_list("IMS image list", images),
            jobs=ims.ImsObjectMap.from_list("IMS job list", jobs),
            public_keys=ims.ImsObjectMap.from_list("IMS public key list", public_keys),
            recipes=ims.ImsObjectMap.from_list("IMS recipe list", recipes)
        )

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "ImsData":
        """
        Returns an ImsData object populated with the data from json_dict
        """
        return ImsData(
            deleted = None if json_dict["deleted"] is None else ImsDeletedData.load_from_json(json_dict["deleted"]),
            images=ims.ImsObjectMap(json_dict["images"]), jobs=ims.ImsObjectMap(json_dict["jobs"]),
            public_keys=ims.ImsObjectMap(json_dict["public_keys"]), recipes=ims.ImsObjectMap(json_dict["recipes"])
        )

    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "deleted": None if self.deleted is None else self.deleted.jsondict,
                 "images": self.images, "jobs": self.jobs, "public_keys": self.public_keys, "recipes": self.recipes }

    @property
    def any_images_keys_recipes(self) -> bool:
        """
        Returns True if any images, recipes, or public keys (not counting deleted ones) are in this object
        """
        return bool(self.images) or bool(self.public_keys) or bool(self.recipes)


    def running_jobs(self) -> bool:
        """
        Returns False if no jobs exist whose status is something other than 'error' or 'success'.
        Returns True otherwise, and also logs errors with details on the applicable jobs.
        """
        # Make sure no jobs are currently running
        jobs_running = False
        for msg in get_running_jobs(self.jobs.values()):
            jobs_running = True
            logging.error(msg)
        return jobs_running


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    def update_with_exported_data(self, exported_ims_data: "ImsData") -> None:
        """
        Update the current IMS data with the exported IMS data.
        Note that this only applies to non-deleted images, public keys, and recipes.
        Non-deleted jobs and all deleted resources are ignored in the exported data
        and left unchanged in the current data.
        """
        self.images.update(exported_ims_data.images)
        self.public_keys.update(exported_ims_data.public_keys)
        self.recipes.update(exported_ims_data.recipes)


def get_running_jobs(jobs: ims.ImsObjectList) -> List[str]:
    """
    Return a list of strings, one describing each job whose status is something other than error or success/
    Returns an empty list if there are no such jobs.
    """
    running_jobs = []
    for job in jobs:
        try:
            if job["status"] in { "error", "success" }:
                continue
            running_jobs.append(f"Job {job['id']} is not complete (status = {job['status']})")
        except KeyError:
            running_jobs.append(f"Job {job['id']} is not complete (no 'status' field found)")
    return running_jobs
