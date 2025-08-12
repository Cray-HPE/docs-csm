# Soft deleted IMS recipe always has `require_dkms` value set to `true`

## Issue description

When IMS recipe is deleted and moves to being classified as a `deleted recipe` it gets assigned `require_dkms=true`
regardless of the `require_dkms` value of the original recipe. If recipe is restored using operation `undelete`,
`require_dkms` retains the value `true`. This can be an issue in following scenario:

- IMS recipe attribute `require_dkms` value is set to `false`.

## Error identification

A symptom of the problem is that if operation `delete` is performed  followed by `undelete` on an IMS recipe then recipe
attribute `require_dkms` value is always set to `true`.

Follow these steps to verify the issue.

1. (`ncn-mw#`) Get the recipe ID with `require_dkms` value set to `false`.

    ```bash
    cray ims recipes list --format json|jq '.[] | select(.require_dkms == false) | .id'|jq -s '.[0]'
    ```

    Example output:

    ```text
    b89827ea-d929-461f-95b6-14cba7983311
    ```

    If the above command does not return a recipe ID, then the procedure documented here is not applicable.

1. (`ncn-mw#`) Soft delete the recipe.

    > In the following command, replace `<RECIPE_ID>` with the value of previous command.

    ```bash
    cray ims recipes delete <RECIPE_ID>
    ```

1. (`ncn-mw#`) Get the details of `soft deleted` recipe and notice the value of `require_dkms` is set to `true`.

    > In the following command, replace `<RECIPE_ID>` with the value used in previous command.

    ```bash
    cray ims deleted recipes describe <RECIPE_ID> --format json|jq '.require_dkms'
    ```

    Example output:

    ```text
    true
    ```

1. (`ncn-mw#`) `undelete` the `soft deleted` IMS recipe.

    > In the following command, replace `<RECIPE_ID>` with the value used in previous command.

    ```bash
    cray ims deleted recipes update <RECIPE_ID> --operation undelete
    ```

1. (`ncn-mw#`) Get the details of restored recipe and notice the value of `require_dkms` is set to `true`.

    > In the following command, replace `<RECIPE_ID>` with the value used in previous command.

    ```bash
    cray ims recipes describe <RECIPE_ID> --format json|jq '.require_dkms'
    ```

    Example output:

    ```text
    true
    ```

## Resolution

1. (`ncn-mw#`) In order to resolve the problem, update the value of `require_dkms` to `false`.

    > In the following command, replace `<RECIPE_ID>` with the value used in `Error identification` phase.

    ```bash
    cray ims recipes update --require-dkms false <RECIPE_ID> --format json
    ```

    Example output:

    ```json
    {
    "arch": "aarch64",
    "created": "2024-07-18T19:47:03.600611",
    "id": "b89827ea-d929-461f-95b6-14cba7983311",
    "link": {
        "etag": "e07f7f535d886fb9a61130a753a2467b",
        "path": "s3://ims/recipes/b89827ea-d929-461f-95b6-14cba7983311/recipe.tar.gz",
        "type": "s3"
    },
    "linux_distribution": "sles15",
    "name": "cray-shasta-csm-sles15sp5-barebones-csm-1.5-aarch64",
    "recipe_type": "kiwi-ng",
    "require_dkms": false,
    "template_dictionary": []
    }
    ```
