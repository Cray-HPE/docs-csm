# Configure End-User UAI Classes for Broker Mode

Each UAI broker will create and manage a single class of end-user UAIs. Setting up UAI classes for this is similar to [Configure a Default UAI Class for Legacy Mode](Configure_a_Default_UAI_Class_for_Legacy_Mode.md) with the following exceptions:

* The `public_ip` flag for brokered UAI classes should be set to `false`
* The `default` flag for brokered UAI classes may be set to `true` or `false` but should, most likely, be set to `false`.

Everything else should be the same as it would be for a legacy mode UAI class.