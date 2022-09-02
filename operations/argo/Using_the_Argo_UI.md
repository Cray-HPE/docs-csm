# Using the Argo UI

This page provides information about using the Argo UI with CSM. The Argo UI is useful for watching the progress of an install or upgrade and debugging. The UI is read-only and will not accept write operations.

* [Access the Argo UI](#access-the-argo-ui)
* [View logs](#view-logs)

## Access the Argo UI

The Argo UI is accessed through a URL. The URL for a system can be found by the following command.

(`ncn-mw#`) Get Argo UI URL

```bash
kubectl get virtualservice -n argo | grep "argo" | awk '{print $3}' 
```

Credentials can be used to access the Argo UI as long as they have been configured in Keycloak.

See [Create Internal User Accounts in the Keycloak Shasta Realm](../security_and_authentication/Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md) for more information.

## View logs

Logs in the Argo UI show output from individual stages of a workflow and are useful for debugging.

To view the logs:

1. Go to the workflows page and click on the desired workflow.
1. Click on the desired stage within the workflow.
1. In the panel describing that stage, click the `main logs` button.
