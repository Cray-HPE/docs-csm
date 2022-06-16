# Configure Prometheus Email Alert Notifications

Configure an email alert notification for all Prometheus Postgres replication alerts: `PostgresReplicationLagSMA`,
`PostgresReplicationServices`, `PostgresqlFollowerReplicationLagSMA`, and `PostgresqlFollowerReplicationLagServices`.

## Procedure

1. Save the current alert notification configuration in case a rollback is needed.

    ```bash
    ncn# kubectl get secret -n sysmgmt-health alertmanager-cray-sysmgmt-health-promet-alertmanager \
            -ojsonpath='{.data.alertmanager.yaml}' | base64 --decode > /tmp/alertmanager-default.yaml
    ```

1. Create a secret and an alert configuration that will be used to add email notifications for the alerts.

    1. Create the secret file.

        ```console
        ncn# cat << 'EOF' > /tmp/alertmanager-secret.yaml
        apiVersion: v1
        data:
          alertmanager.yaml: ALERTMANAGER_CONFIG
        kind: Secret
        metadata:
          labels:
            app: prometheus-operator-alertmanager
            chart: prometheus-operator-8.15.4
            heritage: Tiller
            release: cray-sysmgmt-health
          name: alertmanager-cray-sysmgmt-health-promet-alertmanager
          namespace: sysmgmt-health
        type: Opaque
        EOF
        ```

    1. Create the alert configuration file.

        In the following example file, the Gmail SMTP server is used in this example to relay the notification to `receiver-email@yourcompany.com`.
        Update the fields under `email_configs:` accordingly before running the following command.

        ```console
        ncn# cat << 'EOF' > /tmp/alertmanager-new.yaml
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
        EOF
        ```

1. Replace the alert notification configuration based on the files created in the previous step.

    ```bash
    ncn# sed "s/ALERTMANAGER_CONFIG/$(cat /tmp/alertmanager-new.yaml \
                | base64 -w0)/g" /tmp/alertmanager-secret.yaml \
                | kubectl replace --force -f -
    ```

1. Validate the configuration changes.

    1. View the current configuration.

        ```bash
        ncn# kubectl exec alertmanager-cray-sysmgmt-health-promet-alertmanager-0 \
                -n sysmgmt-health -c alertmanager -- cat /etc/alertmanager/config/alertmanager.yaml
        ```

    1. Check the logs for any errors if the configuration does not look accurate.

        ```bash
        ncn# kubectl logs -f -n sysmgmt-health pod/alertmanager-cray-sysmgmt-health-promet-alertmanager-0 alertmanager
        ```

An email notification will be sent once either of the alerts set in this procedure is `FIRING` in Prometheus.
See `https://prometheus.SYSTEM-NAME.SITE-DOMAIN/alerts` for more information.

If an alert is received, then refer to [Troubleshoot Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md) for more information
about recovering replication.
