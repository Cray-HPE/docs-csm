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
"""Shared Python function library: Parallelize S3 transfers"""

import logging
import queue
import threading
from typing import Callable, Iterable, List, NamedTuple, Union

from python_lib.s3 import S3Url, create_artifact, get_artifact
from python_lib.types import JsonDict

from .exceptions import ImsImportExportError

# Current test has shown this to be the sweet spot, at least when uploading from the
# USB drive
DEFAULT_NUM_UPLOAD_WORKERS=6

# Downloads to the USB drive do not appear to benefit from parallel downloads
DEFAULT_NUM_DOWNLOAD_WORKERS=1

class S3TransferRequest(NamedTuple):
    """
    A request that can be used to specify an upload or download to be performed
    """
    url: S3Url
    filepath: str

class S3TransferError(NamedTuple):
    """
    Associate an error with the S3 transfer which generated it
    """
    request: S3TransferRequest
    error: Exception

class S3TransferResult(NamedTuple):
    """
    For uploads, the response field will be a JsonDict.
    No data is returned from S3 on successful downloads, so
    in that case, the field will be None.
    """
    request: S3TransferRequest
    response: Union[JsonDict, None]


def do_s3_upload(transfer_request: S3TransferRequest) -> JsonDict:
    logging.info("Starting S3 upload of %s", transfer_request.url)
    return create_artifact(transfer_request.url, transfer_request.filepath)


def do_s3_download(transfer_request: S3TransferRequest) -> None:
    logging.info("Starting S3 download of %s", transfer_request.url)
    get_artifact(transfer_request.url, transfer_request.filepath)


def s3_transfer_worker(do_transfer: Callable,
                       work_queue: "queue.Queue[S3TransferRequest]",
                       result_queue: "queue.Queue[S3TransferResult]",
                       error_queue: "queue.Queue[S3TransferError]") -> None:
    """
    As long as the work_queue is not empty and the error_queue is empty, then
    pop an item off the work_queue, call the transfer function on it, and put
    the result into the result_queue. If there is an error, put it in the error_queue.
    """
    # Abort if anyone has hit a problem
    while error_queue.empty():
        try:
            transfer_request = work_queue.get_nowait()
        except queue.Empty:
            return
        try:
            response = do_transfer(transfer_request)
        except Exception as exc:
            logging.exception("Error with S3 transfer of %s", transfer_request)
            error_queue.put_nowait(S3TransferError(request=transfer_request, error=exc))
            return
        logging.debug("Putting result of %s upload onto result_queue", transfer_request)
        try:
            result_queue.put_nowait(S3TransferResult(request=transfer_request, response=response))
        except Exception as exc:
            logging.exception("Error posting results of successful S3 transfer of %s to result queue", transfer_request)
            error_queue.put_nowait(S3TransferError(request=transfer_request, error=exc))
            return


def transfer_s3_artifacts(s3_transfer_requests: Iterable[S3TransferRequest],
                          do_transfer: Callable,
                          num_workers: int) -> List[S3TransferResult]:
    work_queue = queue.Queue()
    error_queue = queue.Queue()
    result_queue = queue.Queue()
    for request in s3_transfer_requests:
        work_queue.put_nowait(request)
    if len(s3_transfer_requests) < num_workers:
        logging.debug("There are only %d S3 transfers required -> reducing num_workers from %d to %d",
                      len(s3_transfer_requests), num_workers, len(s3_transfer_requests))
        num_workers = len(s3_transfer_requests)
    logging.debug("Creating %d worker threads to perform S3 transfers", num_workers)
    worker_kwargs = { "do_transfer": do_transfer, "error_queue": error_queue, "result_queue": result_queue, "work_queue": work_queue }
    workers = [ threading.Thread(target=s3_transfer_worker, kwargs=worker_kwargs) for _ in range(num_workers) ]
    logging.debug("Starting worker threads")
    for worker in workers:
        worker.start()
    logging.debug("Waiting for all worker threads to complete")
    for worker in workers:
        worker.join()
    logging.debug("All worker threads joined")
    if not error_queue.empty():
        raise ImsImportExportError("At least one error happened during S3 transfer")
    s3_transfer_results = []
    while not result_queue.empty():
        s3_transfer_results.append(result_queue.get_nowait())
    if len(s3_transfer_requests) == len(s3_transfer_results):
        return s3_transfer_results
    raise ImsImportExportError(f"Requested {len(s3_transfer_requests)} S3 transfers but received results for {len(s3_transfer_results)}")


def create_s3_artifacts(s3_upload_requests: Iterable[S3TransferRequest],
                        num_workers: Union[int,None] = None) -> List[S3TransferResult]:
    """
    Performs the requested S3 uploads in parallel.
    Returns the results, or raises an exception.
    """
    if not num_workers:
        num_workers = DEFAULT_NUM_UPLOAD_WORKERS
        logging.debug("Defaulting to %d worker threads", num_workers)
    return transfer_s3_artifacts(s3_transfer_requests=s3_upload_requests, do_transfer=do_s3_upload, num_workers=num_workers)


def download_s3_artifacts(s3_download_requests: Iterable[S3TransferRequest],
                          num_workers: Union[int,None] = None) -> None:
    """
    Performs the requested S3 downloads in parallel.
    Returns None if successful, or raises an exception.
    """
    if not num_workers:
        num_workers = DEFAULT_NUM_DOWNLOAD_WORKERS
        logging.debug("Defaulting to %d worker threads", num_workers)
    transfer_s3_artifacts(s3_transfer_requests=s3_download_requests, do_transfer=do_s3_download, num_workers=num_workers)
