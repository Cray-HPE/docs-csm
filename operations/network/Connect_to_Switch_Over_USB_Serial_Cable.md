# Connect to Switch over USB-Serial Cable

In the event that network connectivity issues prevent conventional access to management network switches,
then it is recommended to access them using the serial/COM ports on the management switches.

- [Prerequisites](#prerequisites)
- [Connect](#connect)
- [Troubleshoot]
    - [Manufacturer variation](#manufacturer-variation)
    - [Mellanox](#mellanox)
    - [No USB TTY device](#no-usb-tty-device)

## Prerequisites

A `USB-DB-9` or `USB-RJ-45` cable is connected between the switch and the NCN.

## Connect

(`ncn-mw#`) Use `minicom`, `screen`, or `cu` to connect to the switch's console.

- `screen`

    ```bash
    screen /dev/ttyUSB1
    screen /dev/ttyUSB1 115200
    ```

- `minicom`

    ```bash
    minicom -b 9600 -D /dev/ttyUSB1
    minicom -b 115200 -D /dev/ttyUSB1
    ```

- `cu`

    ```bash
    cu -l /dev/ttyUSB1 -s 115200
    ```

## Troubleshoot

### Manufacturer variation

Some specifics such as BAUDRATE and terminal usage vary per manufacturer.

Refer to the external support/documentation portals for the specific manufacturer (e.g. Aruba, Dell, Mellanox) for more information.

### Mellanox

On Mellanox switches, if the console is not responding when opened, try holding `CTRL` + `R` (or control + `R` for macOS) to initiate a screen refresh. This should take 5-10 seconds.

### No USB TTY device

If there is no device in `/dev/tty*`, then follow `dmesg -w` and try reseating the USB cable (unplug the end in the NCN, and plug it back in).

Observe the `dmesg -w` output. Look for errors pertaining to USB. The cable may be bad, or a reboot may be required.
