# Configure Prometheus Alerta Alert Notifications

Configure an alerta alert notification for  Prometheus Alertmanager alerts.

## Procedure

1. Save the current alert notification configuration in case a rollback is needed.

    ```bash
    kubectl get secret -n sysmgmt-health alertmanager-cray-sysmgmt-health-promet-alertmanager \
            -ojsonpath='{.data.alertmanager.yaml}' | base64 --decode > /tmp/alertmanager-default.yaml
    ```

1. Create a secret and an alert configuration that will be used to add email notifications for the alerts.

    1. Create the secret file.

        ```console
        cat << 'EOF' > /tmp/alertmanager-secret.yaml
        apiVersion: v1
        data:
          alertmanager.yaml: ALERTMANAGER_CONFIG
        kind: Secret
        metadata:
          labels:
            app: prometheus-operator-alertmanager
            chart: prometheus-operator-9.3.1
            heritage: Tiller
            release: cray-sysmgmt-health
          name: alertmanager-cray-sysmgmt-health-promet-alertmanager
          namespace: sysmgmt-health
        type: Opaque
        EOF
        ```

    1. Create the Alerta alert configuration file.

        In the following example file, the Alerta  server is used in this example to send the notification to `http://sma-alerta.sma.svc.cluster.local:8080/webhooks/prometheus`.
        Update the fields under `webhook_configs:` accordingly before running the following command.

        ```console
        cat << 'EOF' > /tmp/alertmanager-new.yaml
        global:
          resolve_timeout: 5m
        route:
          group_by: ['alertname']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 1h
          receiver: 'web.hook'
        receivers:
        - name: 'web.hook'
          webhook_configs:
          - url: 'http://sma-alerta.sma.svc.cluster.local:8080/webhooks/prometheus'
        inhibit_rules:
          - source_match:
              severity: 'critical'
            target_match:
              severity: 'warning'
            equal: ['alertname', 'dev', 'instance']
        EOF
        ```

1. Replace the alert notification configuration based on the files created in the previous step.

    ```bash
    sed "s/ALERTMANAGER_CONFIG/$(cat /tmp/alertmanager-new.yaml \
                | base64 -w0)/g" /tmp/alertmanager-secret.yaml \
                | kubectl replace --force -f -
    ```

1. Validate the configuration changes.

    1. View the current configuration.

        ```bash
        kubectl exec alertmanager-cray-sysmgmt-health-promet-alertmanager-0 \
                -n sysmgmt-health -c alertmanager -- cat /etc/alertmanager/config/alertmanager.yaml
        ```

    1. Check the logs for any errors if the configuration does not look accurate.

        ```bash
        kubectl logs -f -n sysmgmt-health pod/alertmanager-cray-sysmgmt-health-promet-alertmanager-0 alertmanager
        ```

An Alerta notification will be sent once either of the alerts set in this procedure is `FIRING` in Prometheus.
See `https://prometheus.SYSTEM-NAME.SITE-DOMAIN/alerts` for more information.

