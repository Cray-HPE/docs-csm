# NCN Metadata over USB-Serial Cable

In the event that network plumbing is lacking, down, or unconfigured for procuring devices then it is
recommended to use the Serial/COM ports on the spine and leaf switches.

This guide will instruct the user on procuring MAC addresses for the NCNs metadata files
with the serial console.

Mileage may vary, as some obstacles such as BAUDRATE and `terminal` usage vary per manufacturer.

### Common Manufacturers
(click any for links to support/document portals)

- [Aruba][1]
- [Dell][2]
- [Mellanox][3]

## Setup / Connection

This will involve using a preferred utility (`minicom`, `screen`,  or `cu`) for connecting to your 
switches console.

> At this time it is assumed you have connected your USB-DB-9 or USB-RJ-45 cable between your switch and your NCN.

##### screen

```bash
screen /dev/ttyUSB1
screen /dev/ttyUSB1 115200
```
##### minicom
```bash
minicom -b 9600 -D /dev/ttyUSB1
minicom -b 115200 -D /dev/ttyUSB1
```
##### cu
```bash
cu -l /dev/ttyUSB1 -s 115200
```

### Debugging Connections

##### Tip : Mellanox

On Mellanox switches if the console is not responding when opened try holding `CTRL` + `R` (or control + `R` for macOS) to initiate a screen refresh. This should take 5-10 seconds.

##### Tip : No USB TTY Device

If you can't see your device in `/dev/tty*` then follow `dmesg -w` and try reseating your USB cable (unplug the end in the NCN, and plug it back in). Observe the `dmesg -w` output, does it show errors pertaining to USB? The cable may be bad, or you may need to reboot.

## Additional External References

- [USB-B to RJ-45 rs232 Cable][4]
- [USB-B to USB-C adapter][5]

[1]: https://asp.arubanetworks.com/downloads;search=8325;fileContents=User%20Guide
[2]: https://www.dell.com/support/article/en-us/sln316328/dell-emc-networking-os10-info-hub?lang=en#bs_One
[3]: https://docs.mellanox.com/display/MLNXOSv381000/MLNX-OS+User+Manual+v3.8.1000
[4]: https://www.amazon.com/OIKWAN-Essential-Accesory-Ubiquity-Switches/dp/B082VZTB57/ref=sr_1_5?dchild=1&keywords=usb+to+rj-45+serial&qid=1605474086&sr=8-5
[5]: https://www.amazon.com/dp/B086JKTYCR/ref=cm_sw_em_r_mt_dp_FEzSFbE6MSPHW?_encoding=UTF8&psc=1