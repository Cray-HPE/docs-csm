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
"""Shared Python function library: IMS export"""

import logging
from typing import Union

class ExportOptions:
    def __init__(self,
                 target_directory: str,
                 ignore_running_jobs: bool = False,
                 include_deleted: bool = False,
                 exclude_linked_artifacts: bool = False,
                 exclude_links_from_bos: Union[bool, None] = None,
                 exclude_links_from_bss: Union[bool, None] = None,
                 exclude_links_from_product_catalog: Union[bool, None] = None,
                 no_tar: Union[bool, None] = None):
        self.__target_directory = target_directory
        self.__ignore_running_jobs = ignore_running_jobs
        self.__include_deleted = include_deleted
        self.__exclude_linked_artifacts = exclude_linked_artifacts
        if exclude_linked_artifacts:
            if exclude_links_from_bos is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from BOS")
            self.__include_bos = False

            if exclude_links_from_bss is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from BSS")
            self.__include_bss = False

            if exclude_links_from_product_catalog is not True:
                logging.debug("Excluding linked artifacts -> also exclude S3 links from product catalog")
            self.__include_product_catalog = False

            if no_tar is not True:
                logging.debug("Excluding linked artifacts -> will not create tar file")
            self.__create_tarfile = False
            return

        if exclude_links_from_bos is not None:
            self.__include_bos = not exclude_links_from_bos
        else:
            logging.debug("Including linked artifacts -> also include S3 links from BOS")
            self.__include_bos = True

        if exclude_links_from_bss is not None:
            self.__include_bss = not exclude_links_from_bss
        else:
            logging.debug("Including linked artifacts -> also include S3 links from BSS")
            self.__include_bss = True

        if exclude_links_from_product_catalog is not None:
            self.__include_product_catalog = not exclude_links_from_product_catalog
        else:
            logging.debug("Including linked artifacts -> also include S3 links from product_catalog")
            self.__include_product_catalog = True

        if no_tar is not None:
            self.__create_tarfile = not no_tar
        else:
            logging.debug("Including linked artifacts -> also create tar file of exported data")
            self.__create_tarfile = True

    @property
    def ignore_running_jobs(self) -> bool:
        return self.__ignore_running_jobs

    @property
    def include_deleted(self) -> bool:
        return self.__include_deleted

    @property
    def exclude_linked_artifacts(self) -> bool:
        return self.__exclude_linked_artifacts

    @property
    def target_directory(self) -> str:
        return self.__target_directory

    @property
    def include_bos(self) -> bool:
        return self.__include_bos

    @property
    def include_bss(self) -> bool:
        return self.__include_bss

    @property
    def include_product_catalog(self) -> bool:
        return self.__include_product_catalog

    @property
    def create_tarfile(self) -> bool:
        return self.__create_tarfile
