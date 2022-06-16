# Troubleshoot UAS / CLI Authentication Issues

Several troubleshooting steps related to authentication in a UAI.

## Internal Server Error

An error was encountered while accessing Keycloak because of an invalid token.

```bash
# cray uas create --publickey ~/.ssh/id_rsa.pub
Usage: cray uas create [OPTIONS]
Try "cray uas create --help" for help.
Error: Internal Server Error: An error was encountered while accessing Keycloak
```

The `uas-mgr` logs show:

```bash
2020-03-06 18:52:07,642 - uas_auth - ERROR - <class 'requests.exceptions.HTTPError'> HTTPError('401 Client Error: Unauthorized for url: https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/userinfo')
2020-03-06 18:52:07,643 - uas_auth - ERROR - UasAuth HTTPError:401 Client Error: Unauthorized for url: https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/userinfo
```

The Keycloak pod logs shows:

```bash
18:53:19,617 WARN  [org.keycloak.events] (default task-1) type=USER_INFO_REQUEST_ERROR, realmId=028be52c-ceca-4dbd-b765-0386b42b1866, clientId=cray, userId=null, ipAddress=10.40.0.0, error=user_session_not_found, auth_method=validate_access_token
```

This is caused by the authentication token being invalid. This can happen for many reasons, such as the token expiring after its lifetime has ended or the Keycloak server restarting because of a failure or being moved to a different node.

To resolve this issue, run `cray auth login` to refresh the access token.

**Authorization is Local to a Host:** whenever you are using the CLI (`cray` command) on a host (e.g. a workstation or NCN) where it has not been used before, it is necessary to authenticate on that host using `cray auth login`.
There is no mechanism to distribute CLI authorization amongst hosts.

## Invalid Token

```bash
# cray uas create --publickey ~/.ssh/id_rsa.pub
Usage: cray uas create [OPTIONS]
Try "cray uas create --help" for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['name', 'uidNumber', 'preferred_username', 'gidNumber', 'loginShell', 'homeDirectory']
```

To resolve this issue, make sure the `cray` command is configured to use one of the following URLs for an API gateway \(excluding the `/keycloak/realms/shastaendpoint`\).

```bash
# kubectl exec -c api-gateway api-gateway-544d5c676f-682m2 -- curl -s http://localhost:8001/consumers/remote-admin/jwt | python -mjson.tool | grep ""key""
            "key": "https://api-gateway.default.svc.cluster.local/keycloak/realms/shasta",
            "key": "https://api-gw-service-nmn.local/keycloak/realms/shasta",
            "key": "https://mgmt-plane-cmn.local/keycloak/realms/shasta",
# cray config describe | grep hostname
    "hostname": "https://172.30.51.127:30443" <---- 172.30.51.127:30443 will not work


# Change to "https://api-gw-service-nmn.local"
cray init --hostname "https://api-gw-service-nmn.local"
Overwrite configuration file at: /root/.config/cray/configurations/default ? [y/N]: y
Username: user
Password:
Success!

Initialization complete.
```

## Invalid Credentials

```bash
# cray auth login --username <user> --password <wrongpassword>
Usage: cray auth login [OPTIONS]
Try "cray auth login --help" for help.

Error: Invalid Credentials
```

To resolve this issue:

* Log in to Keycloak and verify the user exists.
* Make sure the username and password are correct.

## `cray uas describe <user>` Does Not Work

The `cray uas describe <user>` is no longer a valid command.

```bash
# cray uas describe <user>
Usage: cray uas [OPTIONS] COMMAND [ARGS]...
Try "cray uas --help" for help.

Error: No such command "describe".
```

Use `cray uas list` instead.

```bash
# cray uas list
```

Example output:

```bash
[[results]]
username = ""
uai_host = ""
uai_status = "Running: Ready"
uai_connect_string = ""
uai_img = ""
uai_age = "11m"
uai_name = ""
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot Broker UAI SSSD Cannot Use `/etc/sssd/sssd.conf`](Troubleshoot_Broker_SSSD_Cant_Use_sssd_conf.md)
