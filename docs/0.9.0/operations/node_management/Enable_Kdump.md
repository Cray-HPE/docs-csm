# Enable Kdump

CSM 0.9.x does not have kdump enabled by default.  It is necessary to run the workaround script on each NCN when rebuilding them.

```
ncn-m001# /opt/cray/csm/workarounds/livecd-post-reboot/CASMINST-3341/CASMINST-3341.sh
```