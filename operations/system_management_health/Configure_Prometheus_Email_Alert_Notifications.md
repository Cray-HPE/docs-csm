# Configure Prometheus Email Alert Notifications

Configure an email alert notification for all Prometheus Postgres replication alerts: `PostgresReplicationLagSMA`,
`PostgresReplicationServices`, `PostgresqlFollowerReplicationLagSMA`, and `PostgresqlFollowerReplicationLagServices`.

## Procedure

This procedure can be performed on any master or worker NCN.

1. (`ncn-mw#`) Save the current alert notification configuration, in case a rollback is needed.

    ```bash
    kubectl get secret -n sysmgmt-health alertmanager-cray-sysmgmt-health-promet-alertmanager \
            -ojsonpath='{.data.alertmanager.yaml}' | base64 --decode > /tmp/alertmanager-default.yaml
    ```

1. Create a secret and an alert configuration that will be used to add email notifications for the alerts.

    1. (`ncn-mw#`) Create the secret file.

        Create a file named `/tmp/alertmanager-secret.yaml` with the following contents:

        ```yaml
        apiVersion: v1
        data:
          alertmanager.yaml: ALERTMANAGER_CONFIG
        kind: Secret
        metadata:
          labels:
            app: kube-prometheus-stack-alertmanager
            chart: kube-prometheus-stack-45.1.1
            heritage: Tiller
            release: cray-sysmgmt-health
          name: alertmanager-cray-sysmgmt-health-kube-p-alertmanager
          namespace: sysmgmt-health
        type: Opaque
        ```

    1. (`ncn-mw#`) Create the alert configuration file.

        In the following example file, the Gmail SMTP server is used in this example to relay the notification to `receiver-email@yourcompany.com`.
        Update the fields under `email_configs:` to reflect the desired configuration.

        Create a file named `/tmp/alertmanager-new.yaml` with the following contents:

        ```yaml
        global:
          resolve_timeout: 5m
        route:
          group_by:
          - job
          group_interval: 5m
          group_wait: 30s
          receiver: "null"
          repeat_interval: 12h
          routes:
          - match:
              alertname: Watchdog
            receiver: "null"
          - match:
              alertname: PostgresqlReplicationLagSMA
            receiver:  email-alert
          - match:
              alertname: PostgresqlReplicationLagServices
            receiver:  email-alert
          - match:
              alertname: PostgresqlFollowerReplicationLagSMA
            receiver:  email-alert
          - match:
              alertname: PostgresqlFollowerReplicationLagServices
            receiver:  email-alert
        receivers:
        - name: "null"
        - name: email-alert
          email_configs:
          - to: receiver-email@yourcompany.com
            from: sender-email@gmail.com
            # Your smtp server address
            smarthost: smtp.gmail.com:587
            auth_username: sender-email@gmail.com
            auth_identity: sender-email@gmail.com
            auth_password: xxxxxxxxxxxxxxxx
        ```

1. (`ncn-mw#`) Replace the alert notification configuration based on the files created in the previous steps.

    ```bash
    sed "s/ALERTMANAGER_CONFIG/$(cat /tmp/alertmanager-new.yaml \
                | base64 -w0)/g" /tmp/alertmanager-secret.yaml \
                | kubectl replace --force -f -
    ```

1. Validate the configuration changes.

    1. (`ncn-mw#`) View the current configuration.

        ```bash
        kubectl exec alertmanager-cray-sysmgmt-health-promet-alertmanager-0 \
                -n sysmgmt-health -c alertmanager -- cat /etc/alertmanager/config/alertmanager.yaml
        ```

    1. (`ncn-mw#`) If the configuration does not look accurate, check the logs for errors.

        ```bash
        kubectl logs -f -n sysmgmt-health pod/alertmanager-cray-sysmgmt-health-promet-alertmanager-0 alertmanager
        ```

An email notification will be sent once either of the alerts set in this procedure is `FIRING` in Prometheus.
See `https://prometheus.SYSTEM-NAME.SITE-DOMAIN/alerts` for more information.

If an alert is received, then refer to [Troubleshoot Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md) for more information
about recovering replication.
