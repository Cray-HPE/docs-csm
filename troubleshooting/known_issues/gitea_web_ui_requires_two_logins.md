# Known Issue: Logging into the Gitea web UI requires logging in twice

When using the Gitea web UI, users are redirected to a `keycloak` login.
The redirect is expected; however, the expectation is that logging in on this page should log users into Gitea. Unfortunately, that does not happen.
Instead users are being redirected back to Gitea and have to login again through the Gitea web page using the existing git credentials.
To obtain the git credentials for Gitea see the [Version Control Service](../../operations/configuration_management/Version_Control_Service_VCS.md) documentation.
Currently, logging in twice is the only workaround.
