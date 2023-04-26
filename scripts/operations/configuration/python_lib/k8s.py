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
"""Shared Python function library: Kubernetes"""

import logging
import traceback

import kubernetes
import kubernetes.client
import kubernetes.client.api
import kubernetes.config

from . import common
from .types import JsonObject

# To help for type hinting in other modules
CoreV1API = kubernetes.client.api.core_v1_api.CoreV1Api
V1ClientConfiguration = kubernetes.client.configuration.Configuration
V1ConfigMap = kubernetes.client.models.v1_config_map.V1ConfigMap
V1Secret = kubernetes.client.models.v1_secret.V1Secret
V1Service = kubernetes.client.models.v1_service.V1Service


def log_error_raise_exception(msg: str, parent_exception: Exception = None) -> None:
    """
    1) If a parent exception is passed in, make a debug log entry with its stack trace.
    2) Log an error with the specified message.
    3) Raise a ScriptException with the specified message (from the parent exception, if
       specified)
    """
    if parent_exception is not None:
        logging.debug(traceback.format_exc())
    logging.error(msg)
    if parent_exception is None:
        raise common.ScriptException(msg)
    raise common.ScriptException(msg) from parent_exception


def get_configuration() -> V1ClientConfiguration:
    """
    Creates a default Kubernetes configuration and returns it.
    """
    logging.debug("Loading Kubernetes configuration")
    try:
        kubernetes.config.load_kube_config()
    except Exception as exc:
        log_error_raise_exception(
            "Error loading Kubernetes configuration", exc)
    logging.debug("Getting default copy of Kubernetes configuration")
    try:
        return kubernetes.client.Configuration().get_default_copy()
    except Exception as exc:
        log_error_raise_exception(
            "Error getting default copy of Kubernetes configuration", exc)


def get_api_client() -> CoreV1API:
    """
    Creates a Kubernetes API client and returns it.
    """
    logging.info("Initializing Kubernetes client")
    k8s_config = get_configuration()
    logging.debug("Setting client default Kubernetes configuration")
    try:
        kubernetes.client.Configuration.set_default(k8s_config)
    except Exception as exc:
        log_error_raise_exception(
            "Error setting default Kubernetes configuration", exc)
    try:
        return kubernetes.client.api.core_v1_api.CoreV1Api()
    except Exception as exc:
        log_error_raise_exception("Error obtaining Kubernetes API client", exc)


def get_data_field(k8s_object, label: str) -> JsonObject:
    """
    Returns the data field from the specified object. Raises an exception (using the
    provided label) if there is a problem.
    """
    try:
        return k8s_object.data
    except AttributeError as exc:
        log_error_raise_exception(
            f"Error accessing data field in {label}", exc)


class Client:
    """
    Kubernetes API client object. Takes care of the setup steps and provides simplified API calls.
    """
    def __init__(self):
        self.client = get_api_client()

    def get_config_map(self, name: str, namespace: str) -> V1ConfigMap:
        """
        Wrapper for read_namespaced_config_map function
        """
        configmap_label = f"{namespace}/{name} Kubernetes configmap"
        logging.debug(f"Getting {configmap_label}")
        try:
            return self.client.read_namespaced_config_map(name=name, namespace=namespace)
        except Exception as exc:
            log_error_raise_exception(
                f"Error retrieving {configmap_label}", exc)

    def get_config_map_data(self, name: str, namespace: str) -> JsonObject:
        """
        Calls get_config_map function, then extracts the data field from the response.
        """
        configmap_label = f"{namespace}/{name} Kubernetes configmap"
        configmap = self.get_config_map(name=name, namespace=namespace)
        return get_data_field(configmap, label=configmap_label)

    def get_secret(self, name: str, namespace: str) -> V1Secret:
        """
        Wrapper for read_namespaced_secret function
        """
        secret_label = f"{namespace}/{name} Kubernetes secret"
        logging.debug(f"Getting {secret_label}")
        try:
            return self.client.read_namespaced_secret(name=name, namespace=namespace)
        except Exception as exc:
            log_error_raise_exception(f"Error retrieving {secret_label}", exc)

    def get_secret_data(self, name: str, namespace: str) -> JsonObject:
        """
        Calls get_secret function, then extracts the data field from the response.
        """
        secret_label = f"{namespace}/{name} Kubernetes secret"
        secret = self.get_secret(name=name, namespace=namespace)
        return get_data_field(secret, label=secret_label)

    def get_service(self, name: str, namespace: str) -> V1Service:
        """
        Wrapper for read_namespaced_service function
        """
        service_label = f"{namespace}/{name} Kubernetes service"
        logging.debug(f"Getting {service_label}")
        try:
            return self.client.read_namespaced_service(name=name, namespace=namespace)
        except Exception as exc:
            log_error_raise_exception(f"Error retrieving {service_label}", exc)
