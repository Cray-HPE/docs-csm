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
"""Shared Python function library: logging"""

import logging
import logging.config
import sys


class _ExcludeErrorsFilter(logging.Filter):
    def filter(self, record):
        """Allow through the filter if the log level is less than ERROR"""
        return record.levelno < logging.ERROR


def configure_logging(filename):
    """
    Configures logging, with file logging going to the specified filename
    """
    config = {
        'version': 1,
        'filters': {
            'exclude_errors': {
                '()': _ExcludeErrorsFilter
            }
        },
        'formatters': {
            'file_formatter': {
                'format': ('%(asctime)s.%(msecs)03d | %(process)d | %(name)s | %(pathname)s |'
                           ' %(lineno)s | %(funcName)s | %(levelname)s | %(message)s'),
                'datefmt': '%Y%m%d_%H%M%S'
            },
            'stream_formatter': {
                'format': '%(message)s'
            }
        },
        'handlers': {
            'console_stderr': {
                # Sends log messages with log level ERROR or higher to stderr
                'class': 'logging.StreamHandler',
                'level': 'ERROR',
                'formatter': 'stream_formatter',
                'stream': sys.stderr
            },
            'console_stdout': {
                # Sends log messages with log level INFO or higher, but lower than ERROR, to stdout
                'class': 'logging.StreamHandler',
                'level': 'INFO',
                'formatter': 'stream_formatter',
                'filters': ['exclude_errors'],
                'stream': sys.stdout
            },
            'file': {
                # Sends all log messages to a file
                'class': 'logging.FileHandler',
                'level': 'DEBUG',
                'formatter': 'file_formatter',
                'filename': filename,
                'encoding': 'utf8'
            }
        },
        'root': {
            # In general, this should be kept at 'NOTSET'.
            # Otherwise it would interfere with the log levels set for each handler.
            'level': 'NOTSET',
            'handlers': ['console_stderr', 'console_stdout', 'file']
        },
    }
    logging.config.dictConfig(config)
