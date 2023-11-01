# Paging CFS Records

> **NOTE:** Paging is only available using the v3 CFS API. The v2 API will only return an error is the response size is too large.

For all CFS records that can be listed out \(configurations, sessions and templates\) CFS lists only a limited number of records at a time.
This helps reduce the memory requirements for both the CFS API and for the client, especially on systems with large numbers of components.

By default CFS will only return a number of records in a single query up to the `default_page_size` option, which starts at 1000.
However, this can be overridden at query time with the `limit` parameters.
Pages beyond the first can be requested using the `after_id` parameter, which should be set to the id of the last record in the previous page.
For convenience each response includes a `next` section, which includes the `after_id` that should be used to request the next page, as well as the value of all other parameters needed to ensure consistent paging.

## Paging with the CLI

* (`ncn-mw#`) To limit the number of records returned in a query, use the `--limit` parameter.

    ```bash
    cray cfs v3 components list --limit 1 --format json
    ```

  Example response:

   ```json
    {
      "components": [
        {
          "configuration_status": "configured",
          "desired_config": "example-config",
          "enabled": true,
          "error_count": 0,
          "id": "x3000c0s1b0n0",
          "logs": "ara.cmn.site/hosts?name=x3000c0s11b0n0",
          "tags": {}
        }
      ],
      "next": {
        "after_id": "x3000c0s1b0n0",
        "config_details": false,
        "config_name": "",
        "enabled": null,
        "ids": "",
        "limit": 1,
        "state_details": false,
        "status": "",
        "tags": ""
      }
    }
    ```

* (`ncn-mw#`) To request the next set of records, use the `--after-id` parameter.

    ```bash
    cray cfs v3 components list --limit 1 --after-id x3000c0s1b0n0
    ```

## Changing the default page size

* (`ncn-mw#`) The default page size can be updated with the following command.

    ```bash
    cray cfs v3 options update --default-page-size 500
    ```

Use caution when changing this value as the CFS services will use this value internally.
If this is set too high on large systems the CFS API may struggle unless the memory limits for the CFS API pods are also increased.
This option also controls the size at which the v2 API will throw an error when the response size is too large, so changing this can also impact the v2 API.

For more information on the `default_page_size` option, see [CFS Global Options](CFS_Global_Options.md)

## Programmatic iteration

All responses to CFS queries listing records include a `next` section, which will contain the values needed to query the next page. When no more records are available and the last page is queried, the `next` value will be empty.
This can be used to easily iterate over multiple pages, as seen in the example Python code below where the `next` section is used directly as query parameters for the next query:

```python
def iter_components(**kwargs):
    next_parameters = kwargs
    while True:
        response = requests.get(ENDPOINT, params=next_parameters)
        data = response.json()
        for component in data["components"]:
            yield component
        next_parameters = data["next"]
        if not next_parameters:
            break
```
