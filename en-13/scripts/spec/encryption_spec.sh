#!/usr/bin/env sh
#
# MIT License
#
# (C) Copyright 2022, 2024 Hewlett Packard Enterprise Development LP
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

# Note using function mocks for testing ref:
# https://github.com/shellspec/shellspec#mocking
Describe 'encryption.sh logic'
  Include operations/kubernetes/encryption.sh

  Context 'Utility functionality in stripetcdprefix'
    It 'should strip aescbc: from a string passed'
      When call stripetcdprefix "aescbc:sut"
      The status should equal 0
      The stdout should equal "sut"
    End
    It 'should strip aesgcm: from a string passed'
      When call stripetcdprefix "aesgcm:sut"
      The status should equal 0
      The stdout should equal "sut"
    End
    It 'should strip do nothing when identity is passed'
      When call stripetcdprefix "identity"
      The status should equal 0
      The stdout should equal "identity"
    End
    It 'should strip do nothing when rewrite is passed'
      When call stripetcdprefix "rewrite"
      The status should equal 0
      The stdout should equal "rewrite"
    End
    It 'should strip do nothing when unknown is passed'
      When call stripetcdprefix "unknown"
      The status should equal 0
      The stdout should equal "unknown"
    End
    It 'should strip prefixes correctly when multiple passed'
      When call stripetcdprefix "identity aescbc:aescbc-a2192eeb9b7585151f53f0baf01f577d46936ffe0f97e38988506e01c07906a3"
      The status should equal 0
      The stdout should equal "identity aescbc-a2192eeb9b7585151f53f0baf01f577d46936ffe0f97e38988506e01c07906a3"
    End
  End

  # Valid secret lengths, some caveats apply....
  secret16=0123456789abcdef
  secret24=0123456789abcdeffedcba98
  secret32=0123456789abcdeffedcba9876543210

  # Control if an input is of correct input length, e.g. 16, 24, or 32 bytes
  # long
  Context 'Valid encryption key input lengths'
    It 'secret of length 16 is OK'
      When call validatelen "${secret16}"
      The status should equal 16
    End

    It 'secret of length 24 is OK'
      When call validatelen "${secret24}"
      The status should equal 24
    End

    It 'secret of length 32 is OK'
      When call validatelen "${secret32}"
      The status should equal 32
    End
  End

  # Invalid secret length data
  Context 'Invalid encryption key input lengths'
    It 'invalid length fails'
      When call validatelen "123"
      The status should equal 0
    End

    It 'crazy long input fails'
      When call validatelen "alsjflkdjflkjafljdalskfjldkjsfkjdsfkljfdlkjdf"
      The status should equal 0
    End

    It 'null/empty string fails'
      When call validatelen ""
      The status should equal 0
    End
  End

  # Validate provider types/strings
  Context 'Valid provider provided'
    It 'allows aescbc as a provider'
      When call validprovider aescbc
      The status should equal 1
    End

    It 'allows aesgcm as a provider'
      When call validprovider aesgcm
      The status should equal 1
    End
  End

  Context 'Invalid provider provided'
    It 'fails with a random string that makes no sense'
      When call validprovider abc
      The status should equal 0
    End

    It 'fails with no args'
      When call validprovider
      The status should equal 0
    End

  End

  Context 'Valid validateinput calls'
    # Only used for unit tests, hopefully nobody ever tries to use this secret in
    # real life.
    secretsut=sutsutsutsutsutsutsutsutsutsutsu

    It 'allows a simple identity config'
      When call validateinput identity
      The status should equal 0
      The stdout should equal identity
    End

    It 'sets up aescbc and aesgcm correctly'
      When call validateinput identity aescbc "${secretsut}" aesgcm "${secretsut}"
      The status should equal 0
      The stdout should equal "identity aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U= aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U="
    End

  End

  Context 'Internal function to remove b64 secrets from encryption data'
    It 'yeets out the base64 secret'
      When call tovalid identity aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U= aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U=
      The status should equal 0
      The stdout should equal "identity aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907 aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
    End

  End

  Context 'Invalid validateinput calls'
    It 'fails when called without args'
      When call validateinput
      The status should equal 1
      The stderr should equal "fatal: bug? no args passed to validateinput()"
    End

    It 'fails when called with an even number of args'
      When call validateinput a b
      The status should equal 1
      The stderr should equal "fatal: bug? even number of args for validateinput()"
    End

    It 'fails when called with some random input that makes no sense'
      When call validateinput invalid
      The status should equal 1
      The stderr should equal "fatal: invalid provider specified invalid"
    End

    It 'fails if every arg is just identity'
      When call validateinput identity identity identity
      The status should equal 1
      The stderr should equal "fatal: bug? more than one identity arg provided to validateinput()"
    End

    # Note valid calls will *always* be odd aka identity provider data
    # if we somehow get provider data provider data2 thats invalid/a bug
    It 'fails when called with an even number of args'
      When call validateinput invalid aescbc
      The status should equal 1
      The stderr should equal "fatal: bug? even number of args for validateinput()"
    End

    # A bit redundant but why not make sure calls are kosher
    It 'fails when called with an invalid provider but valid data'
      When call validateinput identity invalid secret16
      The status should equal 1
      The stderr should equal "fatal: invalid provider specified invalid"
    End

    It 'fails when called with a valid provider but invalid data'
      When call validateinput identity aescbc blah
      The status should equal 1
      The stderr should equal "fatal: invalid key length"
    End
  End

  # Make sure the encryptionconfig function works the way we expect it to.
  Context 'Valid encryptionconfig calls'
    # Only used for unit tests, hopefully nobody ever tries to use this secret in
    # real life.
    secretsut=sutsutsutsutsutsutsutsutsutsutsu

    identity() {
      %text
      #|---
      #|apiVersion: apiserver.config.k8s.io/v1
      #|kind: EncryptionConfiguration
      #|resources:
      #|  - resources:
      #|      - secrets
      #|    providers:
      #|      - identity: {}
    }

    beginencryption() {
      %text
      #|---
      #|apiVersion: apiserver.config.k8s.io/v1
      #|kind: EncryptionConfiguration
      #|resources:
      #|  - resources:
      #|      - secrets
      #|    providers:
      #|      - identity: {}
      #|      - aescbc:
      #|          keys:
      #|            - name: "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
      #|              secret: "c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U="
      #|      - aesgcm:
      #|          keys:
      #|            - name: "aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
      #|              secret: "c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3V0c3U="
      #|
    }

    It 'allows a simple identity config'
      When call encryptionconfig identity
      The status should equal 0
      The stdout should equal "$(identity)"
    End

    It 'sets up aescbc and aesgcm correctly'
      When call encryptionconfig identity aescbc "${secretsut}" aesgcm "${secretsut}"
      The status should equal 0
      The stdout should equal "$(beginencryption)"
    End

  End

  # This stuff is rather key to how all this setup is to work, takes the
  # encryptionconfigs generated ^^^ and sets up the k8s path, e.g.
  # /etc/cray/kubernetes/encryption .... and sets up/resets the encryption files. As
  # this is critical to operational aspects, ensure the logic is as expected by
  # stubbing in/using tempdirs to validate we get expected behavior.
  Context 'File setup/symlink validation success cases'
    sutdir=""
    before() { sutdir=$(mktemp -d sut.XXXXXXXXX); }
    after() { rm -fr "${sutdir}"; }

    prefixhook() { PREFIX="${sutdir}"; }
    restartk8s() { return 0; }

    Before 'before' 'prefixhook'
    After 'after'

    Describe 'Edge case of PREFIX not existing'
      # I hope this never exists anywhere...
      noprefixdir() { PREFIX=/sut/no/such/dir; }
      Before 'noprefixdir'

      # We have default.yaml with a symlink of current.yaml
      #
      # We expect a file of sha256sumofcontents.yaml to symlink to current.yaml on
      # a success case. Note this means kubeadm update worked, if that failed current.yaml
      # is not updated. That is a different test block later.
      It 'fails when PREFIX is not an existing directory'
        When call writeconfig
        The status should equal 1
        The stderr should equal "fatal: ${PREFIX} does not exist or is not a directory"
      End
    End

    Describe 'Edge case of PREFIX not being a directory'
      # I hope this never exists anywhere...
      notadir() { PREFIX=/dev/null; }
      Before 'notadir'

      # We have default.yaml with a symlink of current.yaml
      #
      # We expect a file of sha256sumofcontents.yaml to symlink to current.yaml on
      # a success case. Note this means kubeadm update worked, if that failed current.yaml
      # is not updated. That is a different test block later.
      It 'fails when PREFIX is not an existing directory'
        When call writeconfig
        The status should equal 1
        The stderr should equal "fatal: ${PREFIX} does not exist or is not a directory"
      End
    End

    Describe 'Write out a default config, should be a nop and point current.yaml to default.yaml,'
      # I hope this never exists anywhere...
      notadir() { PREFIX=/dev/null; }
      Before 'notadir'

      # We have default.yaml with a symlink of current.yaml
      #
      # We expect a file of sha256sumofcontents.yaml to symlink to current.yaml on
      # a success case. Note this means kubeadm update worked, if that failed current.yaml
      # is not updated. That is a different test block later.
      It 'fails when PREFIX is not an existing directory'
        When call writeconfig
        The status should equal 1
        The stderr should equal "fatal: ${PREFIX} does not exist or is not a directory"
      End
    End

    # This simply restarts the k8s kubeapi pod/containers and makes sure we can
    # see the updated encryption configuration file in the process args.
    Describe 'restartk8s function dependencies'
      # We're running with something we aren't expecting... aka pgrep can't find that file in any process arguments.
      It 'returns non zero when pgrep returns no match'
        sutpgrep() {
          return 1
        }
        When call sutpgrep "/etc/cray/kubernetes/encryption/whatever.yaml"
        The status should equal 1
      End

      It 'returns ok when pgrep returns a kubeapi proces that matches'
        sutpgrep() {
          printf '12345 kube-api\n'
          return 0
        }
        When call sutpgrep "/etc/cray/kubernetes/encryption/whatever.yaml"
        The status should equal 0
        The stdout should equal "12345 kube-api"
      End

      # TODO: What does a failure look like here besides non 0 return code? aka
      # what does stdout/stderr output? Not critical but nice to match what real
      # life has.
      It 'returns nonzero if kubectl delete fails'
        sutkubectldelete() {
          return 1
        }
        When call sutkubectldelete
        The status should equal 1
      End

      It 'returns zero if kubectl delete succeeds'
        sutkubectldelete() {
          printf 'pod "kube-apiserver-ncn-m001" deleted\n' >&2
          return 0
        }
        When call sutkubectldelete
        The status should equal 0
        The stderr should equal 'pod "kube-apiserver-ncn-m001" deleted'
      End
    End

    # Etcd related spelunking code
    #
    # Here to try to prevent users from shooting their own feet off when
    # updating encryption configurations.
    Describe 'etcd suite of functions'
      goal=aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907
      new=aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907

      It 'sutetcdok can determine if etcd is working if it is'
        sutetcdok() {
          printf "etcdctl version: 3.5.0\nAPI version: 3.5\n"
          return 0
        }
        When call sutetcdok
        The stdout should equal "etcdctl version: 3.5.0
API version: 3.5"
        The status should equal 0
      End

      # I can't get etcdctl version to fail ever not sure what it looks like
      # when it fails so just having it return 1, if/when I can get this to fail
      # mimic it here.
      It 'sutetcdok can determine if etcd is working if it is not'
        sutetcdok() {
          return 1
        }
        When call sutetcdok
        The status should equal 1
      End

      # Inspect our secret for its keyvalue to get at if it is encrypted or not,
      # and if it is what the encryption key name is/was.
      #
      # If it can't figure that out returns 1 and the caller gets to determine
      # the right thing to do (bail basically and dump to stderr).
      It 'sutkeyencryption can return identity for an unencrypted key'
        # etcdctl get --print-value-only /registry/secrets/kube-system/cray-k8s-encryption
        # on an unencrypted setup with the default helm key data (for any
        # reviewers there is *NO* secret data in this text)
        identitycontent() {
          %text
          #|k8s
          #|
          #|
          #|v1Secret
          #|
          #|cray-k8s-encryption
          #|                   kube-system"*$1a18ede0-2506-4268-836c-c0062dcfc3de2ϪؘZ$
          #|app.kubernetes.io/managed-byHelmb
          #|changedneverb
          #|currentunknownb
          #|
          #|generation0b
          #|goalunknownb0
          #|meta.helm.sh/release-namecray-k8s-encryptionb-
          #|meta.helm.sh/release-namespace
          #|                              kube-systemz
          #|helmUpdatevϪؘFieldsV1:
          #|{"f:metadata":{"f:annotations":{".":{},"f:changed":{},"f:current":{},"f:generation":{},"f:goal":{},"f:meta.helm.sh/release-name":{},"f:meta.helm.sh/release-namespace":{}},"f:labels":{".":{},"f:app.kubernetes.io/managed-by":{}}},"f:type":{}}Opaque"
        }

        sutetcdctlkeyval() {
            identitycontent
            return 0
        }

        When call sutkeyencryption kube-system cray-k8s-encryption
        The status should equal 0
        The stdout should equal "identity"
      End

      # Same as above but with an aescbc cipher, again, nothing in here is
      # secret its using the sut encryption string in this test suite to encrypt
      # the secret however. But nobody should use sut(repeated) as an encryption
      # secret cipher anyway. This output may be a bit mangled due to there
      # being newlinesetc... all over but it's OK for test data.
      It 'sutkeyencryption can return the cipher string name for an encrypted aescbc key'
        aescbc() {
          %text
          #|k8s:enc:aescbc:v1:aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907:_3dUZ%
          #|Hz6:    G;%@-/'e^?NK[g<,zq~SF7}@<X<CisO!@ΔQm35n3Z9]uNA8725ૺ12R2Gy\a'=t;RIP,(nUY#{>kL5SDeaXwɠR/$dq$
          #|[cNd~2G0gy[-9p]Q%:EnѲmWi-T!>E)z
          #|                               4u?9%3dy
          #|թ`Wvel~tBJ}K
          #|            n#l_I;[TJ>L8,7*'F-<(ۇDjZgq
          #|                                      5SD!#Ӛ6oXV2woz8ݷy'v!_Uu@F<[/}ehCӤ:(AGA$RD0YՌmR4= @+6u>0$yFQ/||
          #|                                                                                                    /7
        }

        sutetcdctlkeyval() {
            aescbc
            return 0
        }

      When call sutkeyencryption kube-system cray-k8s-encryption
        The status should equal 0
        The stdout should equal "aescbc-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
      End

      # Same as above but with an aesgcm cipher, actually just repeated the cbc but as the encrypted data isn't important just copied ^^^ directly out of laziness.
      It 'sutkeyencryption can return the cipher string name for an encrypted aesgcm key'
        aesgcm() {
          %text
          #|k8s:enc:aesgcm:v1:aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907:_3dUZ%
          #|Hz6:    G;%@-/'e^?NK[g<,zq~SF7}@<X<CisO!@ΔQm35n3Z9]uNA8725ૺ12R2Gy\a'=t;RIP,(nUY#{>kL5SDeaXwɠR/$dq$
          #|[cNd~2G0gy[-9p]Q%:EnѲmWi-T!>E)z
          #|                               4u?9%3dy
          #|թ`Wvel~tBJ}K
          #|            n#l_I;[TJ>L8,7*'F-<(ۇDjZgq
          #|                                      5SD!#Ӛ6oXV2woz8ݷy'v!_Uu@F<[/}ehCӤ:(AGA$RD0YՌmR4= @+6u>0$yFQ/||
          #|                                                                                                    /7
        }

        sutetcdctlkeyval() {
            aesgcm
            return 0
        }

        When call sutkeyencryption kube-system cray-k8s-encryption
        The status should equal 0
        The stdout should equal "aesgcm-46d5bd8c2001d07ded05687fe51b517033dc609e69fe4dddaa6e05656cf6e907"
      End

      # FAILURE CASES
      #
      # Not entirely sure what this looks like directly but lets handle an error case of etcdctl get failing for a non existent namespace/keyname pair.
      It 'sutkeyencryption complains on a nonexistent namespace/keyname'
        sutetcdctlkeyval() {
            return 0
        }

        When call sutkeyencryption doesnt exist
        The status should equal 1
        The stdout should equal "dne"
      End

      # Just to be sure a non zero exit code from etcdctl will propogate up right
      #
      # Whatever stdout/err have here isn't a concern or rather we won't care about.
      It 'sutkeyencryption complains on a nonexistent namespace/keyname deadline exceeded'
        sutetcdctlkeyval() {
            printf "stdout\n"
            printf "stderr\n" >&2
            return 1
        }

        When call sutkeyencryption doesnt exist
        The status should equal 1
        The stdout should equal "etcderror"
      End

      It 'sutkeyencryption handles etcd not returning in time correctly'
        sutetcdctlkeyval() {
          printf '{"level":"warn","ts":"2022-09-19T17:50:15.910Z","logger":"etcd-client","caller":"v3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00024c380/#initially=[127.0.0.1:2379]","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection closed"}\nError: context deadline exceeded\n'
          return 1
        }

        When call sutkeyencryption etcd wickedslow
        The status should equal 1
        The stdout should equal "etcdtimeout"
      End

      It 'works with complement set operations'
        When call complement "a b c" "a b"
        The status should equal 0
        The stdout should equal "c"
      End

      It 'works with complement set operations'
        When call complement "a b c" "a b d"
        The status should equal 0
        The stdout should equal "c"
      End

      It 'works with complement set operations'
        When call complement "a b c" "b c"
        The status should equal 0
        The stdout should equal "a"
      End

      It 'works with subset set operations'
        When call subset "a" "a b"
        The status should equal 1
      End

      It 'works with subset set operations'
        When call subset "a b" "a b c"
        The status should equal 1
      End

      It 'works with subset set operations'
        When call subset "a b" "b c"
        The status should equal 0
      End

      It 'works with subset set operations'
        When call subset "a" "a"
        The status should equal 1
      End

      It 'works with union set operations'
        When call union "a b" "b a"
        The status should equal 0
        The stdout should equal "a b"
      End

      # Okie dokie, now the fun bits, this function will loop over every secret
      # and extract out each secret's encryption status of identity or its name.
      #
      # This will be used to determine if what the user is requesting makes any
      # sense whatsoever later on.
      #
      # This covers any subfunctions used as well.
      It 'detects possible user input goals'
        When call usergoalvalid "identity" "identity" "identity"
        The status should equal 0
      End

      It 'detects possible user input goals adding an end goal'
        When call usergoalvalid "identity" "identity ${goal}" "identity"
        The status should equal 0
      End

      It 'detects possible user input goals adding an end goal'
        When call usergoalvalid "identity" "${goal} identity" "identity"
        The status should equal 0
      End

      It 'detects possible user input goals adding an end goal in progress'
        When call usergoalvalid "identity" "identity ${goal}" "identity"
        The status should equal 0
      End

      It 'detects possible user input goals removing a written end goal'
        When call usergoalvalid "identity ${goal}" "identity" "${goal}"
        The status should equal 0
      End

      It 'detects possible user input goals removing an end goal in progress and not written to disk yet'
        When call usergoalvalid "identity" "identity" "identity"
        The status should equal 0
      End

      It 'detects possible user input goals of removing encryption and some etcd data has been written with identity encryption'
        When call usergoalvalid "${goal} identity" "identity ${goal}" "${goal}"
        The status should equal 0
      End

      It 'fails if we have a new goal but are missing an existing goal'
        When call usergoalvalid "identity ${goal}" "identity ${new}" "${goal}"
        The status should equal 1
      End

    End
  End
End
