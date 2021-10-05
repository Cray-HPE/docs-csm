# Grafterm

Visualize metrics dashboards on the terminal, like a simplified and minimalist version of **Grafana** for terminal.

The utility(script) can be found in the /opt/cray/platform-utils directory in all NCNs.

## Running options

Exit with `q` or `Esc`.

### Help

```bash
ncn-m001# ./grafterm.sh --help
```

### List available terminal dashboards

```bash
ncn-m001# ./grafterm.sh --list
```

### Default usage
To view the dashboard, pass the value(dashboard json file) to the `-c` parameter to the script.
The Grafterm will query for all data accessible in the datasource by default, and the dashboard refresh frequency is set to 10 seconds.
```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json
```

### Relative time

```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json -d 3h
```

### Refresh interval

```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json -r 10s
```

```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json  -d 3h -r 10s
```

### Fixed time

Set a fixed time range to visualize the metrics using duration notation. In the following example, the start time is `now-23h` and end time is `now-18h`.

```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json -s 23h -e 18h
```

Set a fixed time range to visualize the metrics using timestamp [ISO 8601] notation.

```bash
ncn-m001# ./grafterm.sh -c critical_services_dashboard.json -s 2021-10-30T11:25:10+05:00 -e 2021-10-30T11:55:10+05:00
```
