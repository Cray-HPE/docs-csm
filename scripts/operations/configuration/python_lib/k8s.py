#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

K8S_CONFIGURATION = None
K8S_API_CLIENT = None


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


def get_configuration() -> kubernetes.client.configuration.Configuration:
    """
    Creates a default Kubernetes configuration and returns it.
    """
    global K8S_CONFIGURATION
    if K8S_CONFIGURATION is None:
        logging.debug("Loading Kubernetes configuration")
        try:
            kubernetes.config.load_kube_config()
        except Exception as exc:
            log_error_raise_exception(
                "Error loading Kubernetes configuration", exc)
        logging.debug("Getting default copy of Kubernetes configuration")
        try:
            K8S_CONFIGURATION = kubernetes.client.Configuration().get_default_copy()
        except Exception as exc:
            log_error_raise_exception(
                "Error getting default copy of Kubernetes configuration", exc)
    return K8S_CONFIGURATION


def get_api_client() -> kubernetes.client.api.core_v1_api.CoreV1Api:
    """
    Creates a Kubernetes API client and returns it.
    """
    global K8S_API_CLIENT
    if K8S_API_CLIENT is None:
        logging.info("Initializing Kubernetes client")
        k8s_config = get_configuration()
        logging.debug("Setting client default Kubernetes configuration")
        try:
            kubernetes.client.Configuration.set_default(k8s_config)
        except Exception as exc:
            log_error_raise_exception(
                "Error setting default Kubernetes configuration", exc)
        try:
            K8S_API_CLIENT = kubernetes.client.api.core_v1_api.CoreV1Api()
        except Exception as exc:
            log_error_raise_exception(
                "Error obtaining Kubernetes API client", exc)
    return K8S_API_CLIENT


def get_secret(name: str, namespace: str) -> kubernetes.client.models.v1_secret.V1Secret:
    """
    Wrapper for read_namespaced_secret function
    """
    api_client = get_api_client()
    secret_label = f"{namespace}/{name} Kubernetes secret"
    logging.debug(f"Getting {secret_label}")
    try:
        return api_client.read_namespaced_secret(name=name, namespace=namespace)
    except Exception as exc:
        log_error_raise_exception(f"Error retrieving {secret_label}", exc)


def get_service(name: str, namespace: str) -> kubernetes.client.models.v1_service.V1Service:
    """
    Wrapper for read_namespaced_service function
    """
    api_client = get_api_client()
    service_label = f"{namespace}/{name} Kubernetes service"
    logging.debug(f"Getting {service_label}")
    try:
        return api_client.read_namespaced_service(name=name, namespace=namespace)
    except Exception as exc:
        log_error_raise_exception(f"Error retrieving {service_label}", exc)
