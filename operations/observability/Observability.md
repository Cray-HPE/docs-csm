# Install and Upgrade Observability Framework

## Overview

The Install and Upgrade Observability Framework includes Goss tests health check results in visual Grafana dashboard providing key insights into the health of an HPC from the simple components to the functional and aggregate view of health.

The automated Time to Install(TTI) and Time to upgrade(TTU) provides us the time and other important details for each portion of the HPC install like when and on what machine a given command was run.
This allows us to dynamically capture and store in a file how long the commands/scripts were running, as well what inactivity time was there from the user, as well as how much debug time.

Instead of remembering to notate and record in excel and confluence pages the time spend in actual work, debug, wait time and total time at multiple parts of install for all the product streams, the automated observability time tracking will do this for us.

The following is a list of the most important features of the framework:

- Established a consistent framework for health checks/validation, metrics, and reporting for all product streams for install and upgrade observability.
  - Inside-out Views
    - Timing dashboard view that lets us focus on a single operation, and from that operation zoom out to the total product installation details.
    - Goss test dashboard view that lets us focus on a single test, and from that test zoom out to the total product test details.
  - Outside-in Views
    - Timing dashboard view that shows total product details, and from that we can zoom in to focus on single operation installation details.
    - Goss test dashboard view that shows total product test details, and from that we can zoom in to focus on single test details.
  - Product stream health

- Drill down health dashboard with roll up.
  - Aggregate checks - Problem/OK counts across each product stream.
  - Functional checks - Product stream functional Goss suites for key areas.
    For example, REST APIs, micro-services, Kubernetes, network, and database health for the specific product stream.
  - Granular checks - Individual Goss tests for component level health checks within a functional area of a given product stream.
    For example, management switch configuration verification, routing table checks on OS, gateway tests, and Container Network Interface (CNI) tests.

- Boot, install, and upgrade duration monitoring.
  This does automatic calculation and reporting of both the time a given section of install/upgrade has taken, as well as metrics on Goss test successes and failures.

- Time, node, product stream, capacity, and other dimensions based health and performance insight.

- Multi-interval continuous health checks.
  This defines and implements regular scheduled health checks to occur both during and after the installation and upgrade.
  We can select the appropriate time interval in the Grafana dashboard to check the results for past six hours, a day, and a week.

- Automate the Observability framework , installation, and configuration of the components involved in the Install and Upgrade Observability Framework in a CSM environment.

- The automatic generation of configurable Grafana dashboards that provide key insights and Key Performance Indicators (KPIs).
  These dashboards show the frequency of errors across the complex systems, include panels to visualize the outliers, and provide a way to identify the trends in the complex system across different dimensions.

The following IUF topics are discussed in the following subsections.

- [Automation of Observability Framework](#automation-of-observability-framework)
  - [Features](#observability-framework-features)
  - [Observability workflow](#observability-workflow)
  - [`systemd` services](#systemd-services)
- [IUF timing dashboard](#iuf-timing-dashboard)
  - [Features](#timing-dashboard-features)
  - [Prometheus metrics using Argo workflow](#prometheus-metrics-using-argo-workflow)
  - [Timing dashboard](#timing-dashboard)
- [Goss tests for PIT and NCN](#goss-tests-for-pit-and-ncn)
  - [Overview](#goss-test-overview)
  - [Workflow](#workflow)
  - [Log file format](#log-file-format)
  - [Grok-exporter deployment, service, and service-monitor](#grok-exporter-deployment-service-and-service-monitor)
  - [Configuration file for the grok-exporter](#configuration-file-for-the-grok-exporter)
  - [Prometheus metrics and Grafana dashboard](#prometheus-metrics-and-grafana-dashboard)
- [Error dashboard](#error-dashboard)
  - [Features](#error-dashboards-features)
  - [Error dashboards](#error-dashboards)

## Automation of Observability Framework

Grok-exporter, Prometheus, and Grafana are instantiated automatically on the PIT node.

### Observability framework features

- Three different services for Prometheus, grok-exporter, and Grafana will be automatically running as a part of PIT node installation.
- Prometheus, grok-exporter, and Grafana containers are deployed with services initially on the PIT node for monitoring before other products are installed.
- Grok-exporter parses the unstructured data from the log files and creates Prometheus metrics.
- Prometheus is used as a time-series database for capturing the metrics.
- All the Grafana dashboards automatically load up.

### Observability workflow

![Observability framework workflow](../../img/operations/AutomationFrameworkWorkflow.png "Observability framework workflow")

### `systemd` services

Running status of the PIT observability services: grok-exporter, Prometheus, and Grafana.

```text
● grok-exporter.service - Grok-exporter
     Loaded: loaded (/usr/lib/systemd/system/grok-exporter.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-01-25 00:04:36 UTC; 6h ago
   Main PID: 22381 (conmon)
      Tasks: 2
     CGroup: /system.slice/grok-exporter.service
             ├─ 22373 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/QHMZY5A5LJYDXJ64OE3VRABE3W:/var/lib/containers/storage/over>
             └─ 22381 /usr/bin/conmon --api-version 1 -c 75b89abbe71f1d55033e42305dd69735f952b8b3eb29eb7cf1064dc159c9ae66 -u 75b89abbe71f1d55033e42305dd6973>

Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:             "IOMaximumBandwidth": 0,
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:             "CgroupConf": null
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:         }
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:     }
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]: ]
Jan 25 00:04:36 redbull-pit podman[22324]: 2023-01-25 00:04:36.016806447 +0000 UTC m=+0.306557966 container init 75b89abbe71f1d55033e42305dd69735f952b8b3eb2>
Jan 25 00:04:36 redbull-pit podman[22324]: 2023-01-25 00:04:36.07000859 +0000 UTC m=+0.359760105 container start 75b89abbe71f1d55033e42305dd69735f952b8b3eb2>
Jan 25 00:04:36 redbull-pit podman[22324]: grok-exporter
Jan 25 00:04:36 redbull-pit grok-exporter[22381]: Starting server on http://redbull-pit:9144/metrics
Jan 25 00:04:36 redbull-pit systemd[1]: Started Grok-exporter.
```

```text
● prometheus.service - Prometheus
     Loaded: loaded (/usr/lib/systemd/system/prometheus.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-01-25 00:05:47 UTC; 6h ago
   Main PID: 25680 (conmon)
      Tasks: 2
     CGroup: /system.slice/prometheus.service
             ├─ 25674 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/NZKANI3GOO3KXVE2HIZI33JUTY:/var/lib/containers/storage/over>
             └─ 25680 /usr/bin/conmon --api-version 1 -c 8221fc0337a5bc8ac706ffeb270c18719caf2c02de8402a047670e578010921f -u 8221fc0337a5bc8ac706ffeb270c187>

Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:993 level=info fs_type=TMPFS_MAGIC
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:996 level=info msg="TSDB started"
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:1177 level=info msg="Loading configuration file" filename=/etc/pro>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:1214 level=info msg="Completed loading of configuration file" file>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:957 level=info msg="Server is ready to receive web requests."
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=manager.go:937 level=info component="rule manager" msg="Starting rule mana>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.240Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674605167>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.242Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.3>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.261Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674612007>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.263Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.7
```

```text
● grafana.service - Grafana
     Loaded: loaded (/usr/lib/systemd/system/grafana.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-02-08 23:06:38 UTC; 4 days ago
   Main PID: 82549 (conmon)
      Tasks: 2
     CGroup: /system.slice/grafana.service
             ├─ 82540 /usr/bin/fuse-overlayfs -o lowerdir=/var/lib/containers/storage/overlay/l/UOU2YMGV3WT2CIASNIEDBIY6OK:/var/lib/containers/storage/overl>
             └─ 82549 /usr/bin/conmon --api-version 1 -c f45f33ad520fb278776cf528dab1fdf619f0b1323e672d29d866f728ce8e2589 -u f45f33ad520fb278776cf528dab1fdf>

Feb 08 23:06:38 redbull-pit grafana[82549]: logger=sqlstore t=2023-02-08T23:06:38.23+0000 lvl=info msg="Connecting to DB" dbtype=sqlite3
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=migrator t=2023-02-08T23:06:38.25+0000 lvl=info msg="Starting DB migrations"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=migrator t=2023-02-08T23:06:38.26+0000 lvl=info msg="migrations completed" performed=0 skipped=393 durati>
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=plugin.manager t=2023-02-08T23:06:38.42+0000 lvl=info msg="Plugin registered" pluginId=input
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=query_data t=2023-02-08T23:06:38.43+0000 lvl=info msg="Query Service initialization"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=live.push_http t=2023-02-08T23:06:38.44+0000 lvl=info msg="Live Push Gateway initialization"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=grafanaStorageLogger t=2023-02-08T23:06:38.54+0000 lvl=info msg="storage starting"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=ngalert t=2023-02-08T23:06:38.54+0000 lvl=info msg="warming cache for startup"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=ngalert.multiorg.alertmanager t=2023-02-08T23:06:38.54+0000 lvl=info msg="starting MultiOrg Alertmanager"
Feb 08 23:06:38 redbull-pit grafana[82549]: logger=http.server t=2023-02-08T23:06:38.55+0000 lvl=info msg="HTTP Server Listen" address=[::]:3000 protocol=http>
```

## IUF timing dashboard

### Timing dashboard features

- Use Argo workflows to collect the install/upgrade timing details.
- Create Argo workflows to get metrics from the details available.
- Generate Prometheus install/upgrade timing metrics.
- Create Grafana dashboard using Prometheus metrics.

### Prometheus metrics using Argo workflow

The start time and end time can be obtained as Prometheus labels for the operations using Argo metrics implementation. The time stamp is recorded at the beginning and end of each operation.

Metrics that are captured for the operations:

- start time
- end time
- duration
- status
- product name
- product version

Metrics that are captured for the stage:

- stage name
- stage type
- stage start time (the earliest start time of the all the operations in the stage)
- stage end time (the latest end time of the all the operations in the stage)
- stage duration (the difference between the stage end time and stage start time)
- stage status (status is marked as succeeded if all the operations' statuses are succeeded and vice versa)

Metrics that are captured for the product:

- product name
- product start time (start time of the process-media stage)
- product end time (start time of the post-install-check stage)
- product status (status is marked as succeeded if all the stages' statuses are succeeded and vice versa)

### Timing dashboard

- Dynamic top-down and bottom-up dashboard to track install/upgrade status of any product, stage, and operation.
- Dashboard calculates the execution time for the install/upgrade of any product, stage, and operation.
- The status of the install/upgrade for product, stage, and operation are failed or succeeded.
- There is a dropdown for selection of the product, stage, and operation. By default all are selected.
  The framework defines and implements regular scheduled health checks to occur both during installation and upgrade, as well as after the installation or upgrade has been completed.
  The frequency can be determined by administrator by running the tests over a period of time and selecting the appropriate time interval in the Grafana dashboard to check the results for past six hours, a day, and a week.
- Separate sections are created in the dashboard to see the details of product, stage, and operation.
- There is a graph showing the duration for each stage and operation is added.

![IUF timing dashboard](../../img/operations/TimingDashboard.png "Timing Dashboard")

## Goss tests for PIT and NCN

### Goss test overview

The observability tooling monitors the logs for Goss tests run by using the automated scripts. These scripts are regularly run during install/upgrade. For each Goss test, metrics are generated on its duration and success or failure.

This framework provides a set of quantifiable metrics used to create a visual Grafana health dashboard of all environments. This provides administrators with insight on which tests fail most, or which clusters have the most problems.

Trend analysis of this data in Grafana across different dimensions may point out statistically where the highest frequency of issues occurs.
It also provides administrators an at-a-glance dashboard where they can visually see the complete system health. This includes the option to drill down from the aggregate view of the environment to the functional areas or the components.

Goss test logs are scraped using grok-exporter and visualized on Grafana using captured data.
[`csm-testing` repository](https://github.com/Cray-HPE/csm-testing/tree/main/goss-testing/) contains all of the tests, suites, and scripts to execute these Goss tests.
Automated scripts run the Goss tests in batches. These batches are based on functionality or the check performed in CSM.

A single Goss test is a YAML file and a collection of these Goss tests can be used together by adding them in another YAML file, called a test suite. These suites can be invoked through the CSM-provided scripts to get a log file with results for the tests.

For example, a Goss test to validate expected Kubernetes nodes exists using the `kubectl` command based on node names pulled from `/etc/hosts` file. The log files generated from automated scripts that run a set of test suites are used.

In order to run the automated scripts, use the complete path of the script. For example, `/opt/cray/tests/install/ncn/automated/ncn-healthcheck`.

### Workflow

![Goss test workflow](../../img/operations/GossWorkflow.png "Goss Workflow")

### Log file format

Individual lines of logs are in the following format for each node or PIT node, test name, and source:

```json
{"log_timestamp": "20230118_094205.821955", "Product": "CSM", "log_script": "print_goss_json_results.py", "log_message": "Test result", "Description": "Validates that 'cray --version' is available and executes successfully on the local system.", "Execution Time (nanoseconds)": 1312368478, "Execution Time (seconds)": 1.312368478, "Node": "ncn-m001", "Result Code": 0, "Result String": "PASS", "Source": "http://ncn-m001.hmn:8997/ncn-healthcheck-master", "Test Name": "Command 'cray --version' Available", "Test Summary": "Command: command_available_1_cray_version: exit-status: matches expectation: [0]"}
```

### Grok-exporter deployment, service, and service-monitor

Grok-exporter is deployed on all of the Kubernetes master nodes, by using node affinity in its deployment.
The service for the grok-exporter is accessible at port `9144`. Service-monitor implementation is for Prometheus to access the metrics that are created by the grok-exporter.

### Configuration file for the grok-exporter

The configuration file for the grok-exporter parses the Goss test log files and creates metrics from them.
grok-exporter version 3 configuration is used for this task and to match log expressions with regular expressions.

The following is an example configuration passed to the grok-exporter to get metrics:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example_name
  namespace: example_namespace
data:
  config.yml: |-
    global:
      config_version: 3
    input:
      type: file
      paths: 
      - /logs/goss_tests/*
      fail_on_missing_logfile: false
    grok_patterns:
      - 'REGEX [regular].*expression'
      - 'EXAMPLE [aA-zZ-].*'
    metrics:
      - type: gauge
        name: example_metric
        help: EXAMPLE METRIC HELP
        match: '{"log_file": "%{REGEX:logfile}", "TEST": "%{EXAMPLE:ex}"}'
        value: '{{`{{.logfile}}`}}'
        labels:
          example_test: '{{`{{.ex}}`}}'
    server:
     port: 9144
```

### Prometheus metrics and Grafana dashboard

After the preceding steps the `goss_tests` metrics are seen in Prometheus when Goss tests are run. Using these metrics, Grafana dashboards are created to shows the Goss tests details visually.

Goss test dashboard features:

- The dashboard has a dropdown for product, suite, and tests.
- By default, all products, suites, and tests are selected for overall Goss tests result.
- The overall product result, total number of the products, products passed, products failed, and its execution time is seen.
- Suite results and test results are seen from the dashboard.
- Node-wise test results are seen with failed nodes, passed nodes, and the suite/test description.

![Goss test dashboard](../../img/operations/GossTestsDashboard.png "Goss Test Dashboard")

## Error dashboard

Error dashboards provide key glance at-a-insights about what is broken and needs attention.

The automatic generation of the desired Prometheus grok-exporter configuration is based upon passing in a set of regular expression patterns to detect.
This includes, but is not limited to, regular expression patterns to match and generate metrics on phases of manual administrator steps, as well as phases of installation scripts and automation.

### Error dashboards features

- Automate Grafana dashboards with error and failure message during CSM upgrade and install.
- Create dashboard for issues comparison across multiple dimensions and clusters.
- Monitor ConMan logs from the PIT node.
- Grok-exporter parses the log files.
- Create the Trend, Error, and Alert frequency dashboard.

### Error dashboards

Dashboards tracking different types of errors during install/upgrade.

- Frequency of message about known issues dashboard
- CSM environments install progress dashboard
- USB Device error tracking dashboard
- Boot PXE error tracking dashboard
- Boot DHCP error tracking dashboard

![Error Dashboard](../../img/operations/ErrorDashboard1.png "CSM Environments Install Progress Dashboard")

![Error Dashboard](../../img/operations/ErrorDashboard2.png "Frequency of message about known issues Dashboard")
