# Omitting Authentication Method In API Call Causes CFS Source Creation To Fail

> This [CFS](../../glossary.md#configuration-framework-service-cfs) issue exists in
> CSM 1.5.0, CSM 1.5.1, CSM 1.5.2, and CSM 1.6.0.

When making a [POST request](../../api/cfs.md#post_source_v3) to create a
[CFS source](../../operations/configuration_management/CFS_Sources.md), the request will
fail with an internal server error if no authentication method is specified,
even though [the CFS API specification](../../api/cfs.md#schemav3sourcecreatecredentials)
lists this parameter as optional and has a default value for it.

This does not happen when using the [Cray CLI](../../glossary.md#cray-cli-cray) to create the source,
because the CLI will specify the default authentication method if the user does not specify it.

When this error happens, a stack trace resembling the following will appear in one
of the CFS API Kubernetes pod logs:

```text
2024-11-11 15:43:19,917 - ERROR   - cray.cfs.api.__main__ - Exception on /v3/sources [POST]
Traceback (most recent call last):
  File "/usr/lib/python3.9/site-packages/flask/app.py", line 2529, in wsgi_app
    response = self.full_dispatch_request()
  File "/usr/lib/python3.9/site-packages/flask/app.py", line 1825, in full_dispatch_request
    rv = self.handle_user_exception(e)
  File "/usr/lib/python3.9/site-packages/flask/app.py", line 1823, in full_dispatch_request
    rv = self.dispatch_request()
  File "/usr/lib/python3.9/site-packages/flask/app.py", line 1799, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)
  File "/usr/lib/python3.9/site-packages/connexion/decorators/decorator.py", line 68, in wrapper
    response = function(request)
  File "/usr/lib/python3.9/site-packages/connexion/decorators/uri_parsing.py", line 149, in wrapper
    response = function(request)
  File "/usr/lib/python3.9/site-packages/connexion/decorators/validation.py", line 196, in wrapper
    response = function(request)
  File "/usr/lib/python3.9/site-packages/connexion/decorators/parameter.py", line 120, in wrapper
    return function(**kwargs)
  File "/app/lib/server/cray/cfs/api/dbutils.py", line 233, in wrapper
    return func(*args, **kwargs)
  File "/app/lib/server/cray/cfs/api/controllers/sources.py", line 145, in post_source_v3
    data = _update_credentials_secret(data)
  File "/app/lib/server/cray/cfs/api/controllers/sources.py", line 199, in _update_credentials_secret
    source = _clean_credentials_data(source)
  File "/app/lib/server/cray/cfs/api/controllers/sources.py", line 209, in _clean_credentials_data
    clean_credentials[field] = credentials[field]
KeyError: 'authentication_method'
```

## Workaround

This issue can be avoided by either using the Cray CLI, or by specifying the authentication method.

## Fix

* This issue did not exist prior to CSM 1.5, because CFS sources were not introduced until CSM 1.5.
* This issue exists in CSM 1.5.0, CSM 1.5.1, CSM 1.5.2, and CSM 1.6.0.
* This issue is fixed in all CSM 1.5 versions starting with CSM 1.5.3.
* This issue is fixed in all CSM 1.6 versions starting with CSM 1.6.1.
* This issue is fixed in all CSM versions starting with CSM 1.7.0.
