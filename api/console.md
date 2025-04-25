<h1 id="console-service">Console Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from
the tabs above or the mobile navigation menu.

The Console Service provides access to node console logs and interactive console sessions
for nodes in the system. These are accessed via websocket connections.

# Base URL

* <a href="wss://api-gw-service-nmn.local/apis/console-operator/console-operator">wss://api-gw-service-nmn.local/apis/console-operator/console-operator</a>

## Workflow: Opening an Interactive Console Session

`GET /interact/{node_id}`

*Interact with the console of `node_id`*

A successful interaction will not return a response. Instead, the connection will be
upgraded to a websocket connection. The client can then send and receive messages
over the websocket connection.

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|
|Authorization|header|string|false|Bearer token for authentication.|
|Connection|header|string|false|"Upgrade"|
|Upgrade|header|string|false|"websocket"|

> Example responses

> 403 Forbidden Response

```json
{
  "message": "string"
}

<h3 id="interact_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|403|[Forbidden Response](https://tools.ietf.org/html/rfc7231#section-6.5.3)|User does not have permission to access the node.|Inline|
|404|[Not Found Response](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The node does not exist.|Inline|

## Workflow: Following Console Logs

`GET /tail/{node_id}`

*Tail the console's log file of `node_id`*

A successful interaction will not return a response. Instead, the connection will be
upgraded to a websocket connection. The client can then receive messages when content is
written to the node's console.

### Parameters

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|Cray-Tenant-Name|header|[TenantName](#schematenantname)|false|Tenant name.|
|Cray-Console-Lines|header|int|false|Number of previous lines to display|
|Cray-Console-Follow|header|string|false|"Upgrade"|
|Authorization|header|string|false|Bearer token for authentication.|
|Connection|header|string|false|"Upgrade"|
|Upgrade|header|string|false|"websocket"|

> Example responses

> 403 Forbidden Response

```json
{
  "message": "string"
}

<h3 id="tail_get-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|403|[Forbidden Response](https://tools.ietf.org/html/rfc7231#section-6.5.3)|User does not have permission to access the node.|Inline|
|404|[Not Found Response](https://tools.ietf.org/html/rfc7231#section-6.5.4)|The node does not exist.|Inline|

<h2 id="schematenantname">V2TenantName</h2>

```json
"string"

```

Name of the tenant that owns this resource. Only used in environments
with multi-tenancy enabled. An empty string or null value means the resource
is not owned by a tenant. The absence of this field from a resource indicates
the same.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string¦null|false|read-only|Name of the tenant that owns this resource. Only used in environments<br>with multi-tenancy enabled. An empty string or null value means the resource<br>is not owned by a tenant. The absence of this field from a resource indicates<br>the same.|

## Code Samples

Here is sample python code to create a websocket client for interacting with both console
endpoints. This code uses the `websockets` library to create a websocket client and
`aioconsole` to handle user input. The code is designed to be run in an asyncio event loop.

```python
import asyncio
import websockets
import aioconsole
import json

###########################################################################
# helper function to run the websocket terminal interaction
###########################################################################
async def websocket_terminal_interaction(ctx, endpoint: str, headers: dict[str,str]) -> str:
    # set up the return value
    errMsg = ""
    
    # pull information from context
    auth = ctx.obj["auth"]
    tenant = ctx.get('core.tenant', "")

    # add auth header
    token = ""
    if auth and auth.session and auth.session.access_token:
        token = auth.session.access_token
    if token != "":
        headers["Authorization"] = f"Bearer {token}"

    # add tenant header
    if tenant:
        headers["Cray-Tenant-Name"] = tenant

    # build the uri from the hostname and endpoint - note secure websocket
    uri = f"wss://api-gw-service-nmn.local/{endpoint}"

    try:
        # connect to the websocket
        async with websockets.connect(uri, additional_headers=headers) as websocket:
            print(f"Connected to {uri}")

            async def send_messages():
                while True:
                    try:
                        message = await aioconsole.ainput("")
                        await websocket.send(message)
                    except asyncio.CancelledError:
                        break
                    except Exception as e:
                        print(f"Error sending message: {e}")
                        break

            async def receive_messages():
                while True:
                    try:
                        message = await websocket.recv()
                        print(f"{message}", end='', flush=True)
                    except websockets.ConnectionClosed:
                        print("Connection closed by the server.")
                        break
                    except Exception as e:
                        print(f"Error receiving message: {e}")
                        break

            send_task = asyncio.create_task(send_messages())
            receive_task = asyncio.create_task(receive_messages())

            done, pending = await asyncio.wait(
                [send_task, receive_task],
                return_when=asyncio.FIRST_COMPLETED,
            )

            for task in pending:
                task.cancel()
    except websockets.InvalidStatus as e:
        # Expect this to be an unauthorized tenant, try to pull details
        # from the response body
        errMsg = "Websocket connection failed"
        body = e.response.body
        if body:
            data = json.loads(body.decode('utf-8'))
            errMsg = f"{data.get('message', errMsg)}"
    except websockets.ConnectionClosed as e:
        # handle the connection getting closed
        errMsg = f"Connection closed: {e}"
        body = e.response.body
        if body:
            data = json.loads(body.decode('utf-8'))
            errMsg = f"{data.get('message', errMsg)}"
    except Exception as e:
        # gracefully handle any other exceptions
        errMsg = f"Error: {e}"

    return errMsg

###########################################################################
# cray console interact
###########################################################################
def interact(ctx, xname):
    """ Interact with the console. """
    headers = {}
    endpoint = f"apis/console-operator/console-operator/interact/{xname}"
    errMsg = asyncio.run(websocket_terminal_interaction(ctx, endpoint, headers))

    # if there was an error, print the help, then the error message
    if errMsg:
        print(f"\n\nERROR: {errMsg}")

###########################################################################
# cray console log
###########################################################################
def tail(ctx, xname, lines, follow):
    """ Tail the console output. """

    # pull out the options and load into the headers
    headers = {}
    if lines:
        headers["Cray-Console-Lines"] = str(lines)
    if follow:
        headers["Cray-Console-Follow"] = str(follow)

    # open the websocket
    endpoint = f"apis/console-operator/console-operator/tail/{xname}"
    errMsg = asyncio.run(websocket_terminal_interaction(ctx, endpoint, headers))

    # if there was an error, print the help, then the error message
    if errMsg:
        print(f"\n\nERROR: {errMsg}")
```
