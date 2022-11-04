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

# Note using function mocks for testing ref:
# https://github.com/shellspec/shellspec#mocking
Describe 'encryption.sh logic'
  Include scripts/operations/node_management/encryption.sh

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

  Context 'Invalid encryptionconfig calls'
    It 'fails when called without args'
      When call encryptionconfig
      The status should equal 1
      The stderr should equal "fatal: bug? no args passed to encryptionconfig()"
    End

    It 'fails when called with an even number of args'
      When call encryptionconfig a b
      The status should equal 1
      The stderr should equal "fatal: bug? even number of args for encryptionconfig()"
    End

    It 'fails when called with some random input that makes no sense'
      When call encryptionconfig invalid
      The status should equal 1
      The stderr should equal "fatal: invalid provider specified invalid"
    End

    It 'fails if every arg is just identity'
      When call encryptionconfig identity identity identity
      The status should equal 1
      The stderr should equal "fatal: bug? more than one identity arg provided to identityconfig()"
    End

    # Note valid calls will *always* be odd aka identity provider data
    # if we somehow get provider data provider data2 thats invalid/a bug
    It 'fails when called with an even number of args'
      When call encryptionconfig invalid aescbc
      The status should equal 1
      The stderr should equal "fatal: bug? even number of args for encryptionconfig()"
    End

    # A bit redundant but why not make sure calls are kosher
    It 'fails when called with an invalid provider but valid data'
      When call encryptionconfig identity invalid secret16
      The status should equal 1
      The stderr should equal "fatal: invalid provider specified invalid"
    End

    It 'fails when called with a valid provider but invalid data'
      When call encryptionconfig identity aescbc blah
      The status should equal 1
      The stderr should equal "fatal: invalid key specified blah"
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

      It 'returns ok when pgrep returns a kubeapi process that matches'
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
  End
End
