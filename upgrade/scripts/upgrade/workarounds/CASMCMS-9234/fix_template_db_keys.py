#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
#

from bos.common.tenant_utils import get_tenant_aware_key
from bos.server.redis_db_utils import get_wrapper
import sys

temp_db = get_wrapper(db='session_templates')
renamed = 0
for db_key, data in temp_db.get_all_as_dict().items():
    if not data:
        continue
    st_name = data.get('name', None)
    if not st_name:
        continue
    st_tenant = data.get('tenant', "")
    expected_db_key = get_tenant_aware_key(st_name, st_tenant)
    if expected_db_key == db_key:
        continue
    print(f"Fixing: Template '{st_name}' (tenant: '{st_tenant}') db_key = '{db_key}' does not match expected db_key = '{expected_db_key}'")
    temp_db.rename(db_key, expected_db_key)
    renamed+=1
print(f"{renamed} templates renamed")
if renamed:
    # Exit 57 to communicate that templates were renamed, so a fresh export of BOS data should be performed
    sys.exit(57)
