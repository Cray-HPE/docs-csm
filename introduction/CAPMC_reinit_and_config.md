# CAPMC Reinit and Configuration Notice

CAPMC is now capable of doing a reinit of hardware that does not support
GracefulRestart or ForceRestart. This is done by powering off the target
component and then powering it back on. This behavior is enabled by default and
controlled by a setting in the CAPMC configmap. Along with reinit is the
ability to control other aspects of CAPMCs behavior. To do this, the CAPMC
configmap must be modified to include a CapmcConfiguration section.

## Instructions

1. Edit the configmap

```
ncn-m001# kubectl edit configmaps -n services cray-capmc-configuration
```
At the end of the config.toml section, after the lines
```
    # Administratively defined maximum allowable system power consumption,
    # specified in watts
    PowerBandMax = 0
```
add the following section
```
    [CapmcConfiguration]

    # Number of workers that are available to execute in parallel for Redfish calls
    # ActionMaxWorkers = 1000

    # CAPMC behavior for a power action that target hardware does not support
    # Valid options: simulate, ignore, error
    #   simulate - For components that do not support GracefulRestart or
    #              ForceRestart, simulate will turn the node Off then On again
    #   ignore - Skip the component but notify the user it was ignored
    #   error - Halt the power operation and notify the user
    # OnUnsupportedAction = "simulate"

    # CAPMC will check power state of components when an Off request has been
    # issued. CAPMC will return from the Off request when it has verified that the
    # target components are off or if the number of retries have been exceeded.
    # WaitForOffRetries = 4
    # Amount of time to sleep between checks of component power state for Off.
    # WaitForOffSleep = 15
```
To change a setting, uncomment the line and modify the setting to a valid value.

Save and exit from the confimap.

2. Restart CAPMC
```
kubectl rollout restart -n services deployment cray-capmc
```

3. Verify CAPMC started with the expected settings
```
ncn-m001:# kubectl logs -n services -l app.kubernetes.io/name=cray-capmc -c cray-capmc --tail -1 | egrep -A 5 Configuration
2022/01/05 22:12:41 capmcd.go:513: Configuration loaded:
2022/01/05 22:12:41 capmcd.go:514: 	Max workers: 1000
2022/01/05 22:12:41 capmcd.go:515: 	On unsupported action: simulate
2022/01/05 22:12:41 capmcd.go:516: 	Reinit seq: [Off ForceOff Restart ForceRestart On ForceOn NMI]
2022/01/05 22:12:41 capmcd.go:517: 	Wait for off retries: 4
2022/01/05 22:12:41 capmcd.go:518: 	Wait for off sleep: 15
--
2022/01/06 23:40:50 capmcd.go:513: Configuration loaded:
2022/01/06 23:40:50 capmcd.go:514: 	Max workers: 1000
2022/01/06 23:40:50 capmcd.go:515: 	On unsupported action: simulate
2022/01/06 23:40:50 capmcd.go:516: 	Reinit seq: [Off ForceOff Restart ForceRestart On ForceOn NMI]
2022/01/06 23:40:50 capmcd.go:517: 	Wait for off retries: 4
2022/01/06 23:40:50 capmcd.go:518: 	Wait for off sleep: 15
--
2022/01/06 18:12:17 capmcd.go:513: Configuration loaded:
2022/01/06 18:12:17 capmcd.go:514: 	Max workers: 1000
2022/01/06 18:12:17 capmcd.go:515: 	On unsupported action: simulate
2022/01/06 18:12:17 capmcd.go:516: 	Reinit seq: [Off ForceOff Restart ForceRestart On ForceOn NMI]
2022/01/06 18:12:17 capmcd.go:517: 	Wait for off retries: 4
2022/01/06 18:12:17 capmcd.go:518: 	Wait for off sleep: 15
```

