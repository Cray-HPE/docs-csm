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
from typing import NamedTuple

from python_lib import ims

from python_lib.types import JsonDict

class ImsDeletedData(NamedTuple):
    images: ims.ImsObjectMap
    public_keys: ims.ImsObjectMap
    recipes: ims.ImsObjectMap

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls) -> "ImsDeletedData":
        """
        Collects the information on the deleted resources in IMS and returns an ImsDeletedData
        object populated with it.
        """
        logging.info("Recording list of deleted IMS images")
        deleted_images = ims.list_deleted_images()
        logging.info("Recording list of deleted IMS public keys")
        deleted_public_keys = ims.list_deleted_public_keys()
        logging.info("Recording list of deleted IMS recipes")
        deleted_recipes = ims.list_deleted_recipes()
        return ImsDeletedData(
            images=ims.ImsObjectMap.from_list("IMS deleted image list", deleted_images),
            public_keys=ims.ImsObjectMap.from_list("IMS deleted public key list", deleted_public_keys),
            recipes=ims.ImsObjectMap.from_list("IMS deleted recipe list", deleted_recipes)
        )

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "ImsDeletedData":
        """
        Returns an ImsDeletedData object populated with the data from json_dict
        """
        return ImsDeletedData(images=ims.ImsObjectMap(json_dict["images"]),
                              public_keys=ims.ImsObjectMap(json_dict["public_keys"]),
                              recipes=ims.ImsObjectMap(json_dict["recipes"]))

    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "images": self.images, "public_keys": self.public_keys, "recipes": self.recipes }
