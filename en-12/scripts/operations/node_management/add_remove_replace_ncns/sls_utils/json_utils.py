# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
"""Functions to manage input/output of SLS data as JSON."""
import json
import sys

import jsonschema


def validate(schema_file, sls_data):
    """Validate SLS Networks with JSON schema.

    Args:
        schema_file (str): Name of the SLS schema file
        sls_data (dict): Dictionary of the SLS Networks structure
    """
    with open(schema_file, "r") as file:
        json_schema = json.load(file)

    # TODO: Enable ability to store/ref multiple schemas. A bit like...
    # x schemastore = {}
    # x schema = None
    # x fnames = os.listdir(schema_search_path)
    # x for fname in fnames:
    # x     fpath = os.path.join(schema_search_path, fname)
    # x     if fpath[-5:] == ".json":
    # x         with open(fpath, "r") as schema_fd:
    # x             schema = json.load(schema_fd)
    # x             if "id" in schema:
    # x                 schemastore[schema["id"]] = schema
    # x
    # x schema = schemastore.get("http://mydomain/json-schema/%s" % schema_id)
    # x Draft4Validator.check_schema()
    # x resolver = RefResolver("file://%s.json" % os.path.join(schema_search_path, schema_id), schema, schemastore)
    # x Draft4Validator(schema, resolver=resolver).validate(json_data)

    resolver = jsonschema.RefResolver(base_uri=schema_file, referrer=json_schema)

    # x validator = jsonschema.Draft7Validator(
    # x     schema=json_schema,
    # x     resolver=resolver,
    # x     format_checker=jsonschema.draft7_format_checker
    # x )
    validator = jsonschema.Draft4Validator(
        schema=json_schema,
        resolver=resolver,
        format_checker=jsonschema.draft4_format_checker,
    )

    try:
        validator.check_schema(json_schema)
    except jsonschema.exceptions.SchemaError as err:
        print(f"Schema {schema_file} is invalid: {[x.message for x in err.context]}\n")
        sys.exit(1)

    errors = sorted(validator.iter_errors(sls_data), key=str)
    if errors:
        print("SLS JSON failed schema checks:")
        for error in errors:
            print(f"    {error.message} in {error.absolute_path}")
        sys.exit(1)
