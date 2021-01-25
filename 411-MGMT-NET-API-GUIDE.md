# Management Network API Guide

This page describes how to use the API to interact with the management network switches.
Add link to current tool set

# Aruba

- The first requirement is to have the API and remote access enabled.
configuration
```
ssh server vrf default
ssh server vrf mgmt
https-server vrf default
https-server vrf mgmt
https-server rest access-mode read-write
```
- 