# Configure API Gateway Retries in SAT

The `retries` and `backoff` settings in the `api_gateway` section of the SAT
configuration file controls how many times SAT will retry a failed request and
the delay between retries. These settings can be adjusted to improve resilience
in environments with intermittent network issues.

1. Find the SAT configuration file at `~/.config/sat/sat.toml`, and look for a
   section like this:

   ```toml
   [api_gateway]
   retries = 5
   backoff = 0.2
   ```

   In this example, SAT using 5 `retries` and 0.2 `backoff` interval.

1. Change these lines by modifying the `retries` and `backoff` values as needed.
   For example:

   ```toml
   [api_gateway]
   retries = 10
   backoff = 0.5
   ```

    This will set SAT to retry failed requests up to 10 times with a backoff

1. You can also override these settings at runtime using the
   `--api-retries` and `--api-backoff` command-line arguments.
    These options must be added immediately after `sat` and
    before any SAT subcommand

    For example:

    ```bash
    sat --api-retries 3 --api-backoff 0.5 <sub-command>
    ```

   This will retry API calls up to 3 times with a `backoff` factor of 0.5 seconds.

## Retry Behavior

- Retries are implemented using the `urllib3.util.Retry` class. It will only occur for
  status codes in the 500 range (e.g., server errors) or for network errors.
  Errors like "400 Bad Request" or "403 Forbidden" will not trigger retries.
- The `backoff delay` is calculated as:

    ```bash
    BACKOFF_FACTOR * (2^(numRetries-1))
    ```

    For example, with a backoff factor of `0.5` and `3` retries, the delays between retries will be:
    - 1st retry: 0.5 seconds
    - 2nd retry: 1.0 seconds
    - 3rd retry: 2.0 seconds

These options are documented in the main sat(8) man page.
Refer to the man page for additional details on using these options effectively.
