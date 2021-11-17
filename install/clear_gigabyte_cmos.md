# Clear Gigabyte CMOS

Because of a bug in the Gigabyte firmware, the Shasta 1.5 install may negatively impact Gigabyte motherboards when attempting to boot using bonded Mellanox network cards. The result is a board that is unusable until a CMOS clear is physically done via a jumper on the board itself.

A patched firmware release (newer than C20 BIOS) is expected to be available for a future release of Shasta. It is recommended that Gigabyte users wait for this new firmware before attempting an installation of Shasta 1.5. The procedure to recover the boards is included below.

> All firmware can be found with HFP package provided with the Shasta release.

## Clear BIOS settings by jumper

1. Pull the power cables or blade server from the chassis, and open the system top cover.
2. Move the Clear CMOS Jumper to 2-3, and wait 2 to 3 seconds.
3. Move the Clear CMOS Jumper to 1-2.

### Motherboard MZ62-HD0-00/-YF for Gigabyte H262 chassis
![Diagram of Motherboard mz62-hd0-00/-yf for Gigabyte h262](../img/cmos1.png)

### Motherboard MZ32-AR0-00/-YF for Gigabyte R272 chassis
![Diagram of Motherboard mz32-ar0-00/-yf for Gigabyte r272](../img/cmos2.png)

### Motherboard MZ92-FS0-00/-YF for Gigabyte R282 chassis
![Diagram of Motherboard mz92-fs0-00/-yf for Gigabyte r282](../img/cmos3.png)
