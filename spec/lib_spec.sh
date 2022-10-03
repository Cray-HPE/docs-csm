#!/usr/bin/env sh
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

Describe 'lib.sh logic'
  Include lib/lib.sh

  tmpdir="${TMPDIR:-/tmp}/lib-tmp"
  json="${tmpdir}/json"
  notjson="${tmpdir}/notjson"

  Before 'setup'
  After 'teardown'

  setup() {
      teardown
      install -dm755 "${tmpdir}"
      cat <<EOF > "${json}"
{"sut": "json"}
EOF

      cat <<EOF > "${notjson}"
I am not json
EOF
  }

  teardown() {
    rm -fr "${tmpdir}"
  }

  Context 'curl wrapper basic success'
    curl() {
      %text
      #|200
      return 0
    }

    It 'wraps curl'
      When call sutcurl uri://ok
      The status should equal 0
    End
  End

  Context 'curl wrapper with success output hook'
    Before 'hooksetup'
    hooksetup() {
        export CURLFN=printcurloutputonok
    }
    curl() {
      %text
      #|200
      return 0
    }
    It 'wraps curl and prints'
      When call sutcurl uri://ok
      The status should equal 0
      The stdout should equal "200"
    End
  End

  Context 'curl wrapper informational output hook'
    Before 'hooksetup'
    hooksetup() {
        export CURLFN=echocommand
    }
    curl() {
      %text
      #|200
      return 0
    }
    result() {
        %text
        #|info: curl uri://ok
        #|rc = 0
        #|output = 200
    }
    It 'wraps curl and prints'
      When call sutcurl uri://ok
      The status should equal 0
      The stdout should equal "$(result)"
    End
  End

  Context 'curl wrapper informational output hook'
    Before 'hooksetup'
    hooksetup() {
        export CURLFN=returnoncurlfailure
    }
    curl() {
      printf "000\n" >&2
      return 42
    }
    result() {
        %text
        #|command:
        #|curl uri://ok
        #|rc:
        #|42
        #|output:
        #|000
    }
    It 'wraps curl and prints'
      When call sutcurl uri://ok
      The status should equal 42
      The stderr should equal "$(result)"
    End
  End

  Context 'jq wrapper basic success'
    It 'wraps jq'
      When call sutjq '.' "${json}"
      The status should equal 0
    End
  End

  Context 'jq wrapper with success output hook'
    Before 'hooksetup'
    hooksetup() {
        export JQFN=printjqoutputonok
    }
    It 'wraps jq and prints output'
      When call sutjq '.' "${json}"
      The status should equal 0
      The stdout should equal '{
  "sut": "json"
}'
    End
    It 'wraps jq and prints output again'
      When call sutjq '.sut' "${json}"
      The status should equal 0
      The stdout should equal '"json"'
    End
    It 'wraps jq and prints output again again'
      When call sutjq -r '.sut' "${json}"
      The status should equal 0
      The stdout should equal "json"
    End
  End

  Context 'jq wrapper with failure output hook'
    Before 'hooksetup'
    hooksetup() {
        export JQFN=printjqoutputonok
        export JQTESTFAILFN=jqretry
    }
    result() {
      cat <<EOF
command:
jq . ${notjson}
rc: 4
output: parse error: Invalid numeric literal at line 1, column 2
file ${notjson} content:
I am not json
EOF
        %text
    }

    It 'wraps jq and prints output'
      When call sutjq '.' "${notjson}"
      The status should equal 4
      The stderr should equal "$(result)"
    End
  End
End
