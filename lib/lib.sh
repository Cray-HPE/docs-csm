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

# This uses shellspec for testing, docs here:
# https://github.com/shellspec/shellspec/tree/master/docs
# Examples here:
# https://github.com/shellspec/shellspec/tree/master/examples

# Do not introduce bashisms into this library!
#
# All lib shell should Presume to be run with set -e and set -u. Pipes are and
# should be allowed to fail within this library, pipefile is not portable and
# shouldn't be depended upon for error checking. If a command fails that needs
# to be checked not piped into another command.
#
# posix/bourne shell only c shells need not apply, to ensure this is the case
# run make test-all to have shellspec run against sh (presuming it isn't bash)
# bash and ksh. Future work will integrate this into build processes, thats a
# future task. Presumes you have all the shells installed no attempt is made to
# detect if they aren't it will just fail.
#
# This will ensure all shell in this library can be used by any bourne shell
# intepreter. The rationale here is to ensure future portability to limited
# environments as well as to operating systems that may not have /bin/sh as
# bash.
#
# Do not under any circumstance call exit in this library! shellspec will break
# and it will be obvious make test or make test-all was not run.
#
# Exceptions to the exit clause are hook functions that are intended to exit
# when called.

# Where we store all our temp dirs/files for anything this lib does.
RUNDIR="${TMPDIR:-/tmp}/docs-csm-lib-$$"

# Callers of this script need to call this in an exit handler
libcleanup() {
  rm -fr "${RUNDIR}"
}

mkrundir() {
  install -dm755 "${RUNDIR}"
}

# Create a tempfile using ${RUNDIR} as the prefix, pass in an arg of what the
# files prefix name should be.
libtmpfile() {
  prefix="${1:-caller-did-not-pick-a-name}"
  mkrundir
  tmpfile=$(mktemp -p "${RUNDIR}" "${prefix}-XXXXXXXX")
  rc=$?
  echo "${tmpfile}"
  return "${rc}"
}

# Used by the curl wrapper to allow logging of args on function start or to
# control how that function behaves.
CURLENTRYFN=${CURLENTRYFN-}

hookcurlentry() {
  if [ -n "${CURLENTRYFN}" ]; then
    "${CURLENTRYFN}" "$@"
  fi
}

# Same hook curl wrapper function exit and let it handle any decisions
CURLEXITFN=${CURLEXITFN-}

hookcurlexit() {
  if [ -n "${CURLEXITFN}" ]; then
    "${CURLEXITFN}" "$@"
  fi
}

# For now default will be to fail if curl could not return 0, or did not receive
# http 200 back. For both the action will be to fail
if [ "${__SOURCED__:+sut}" != "sut" ]; then
  CURLFN=${CURLFN-}
else
  CURLFN=${CURLFN-}
fi

hookcurl() {
  if [ -n "${CURLFN}" ]; then
    "${CURLFN}" "$@"
  fi
}

# Some default hooks one can use in caller scripts
warnoncurlfailure() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -gt 0 ]; then
    printf "warn: curl rc != 0 got: %s output: %s\n" "${rc}" "${output}" >&2
  fi
}

# Warn if curl output which should just be the http return code, isn't 200
#
# Note generally if things truly fail in curl, the output is 000 for seemingly
# entirely invalid inputs.
warnnonhttpok() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${output}" -ne "200" ]; then
    printf "warn: http != 200 got: %s\n" "${output}" >&2
  fi
}

# Don't use this unless you truly want the exit call
exitoncurlfailure() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -gt 0 ]; then
    printf "fatal command:\n%s\nrc:\n%s\noutput:\n%s\n" "$*" "${rc}" "${output}" >&2
    exit "${rc}"
  fi
}

# exit if we don't get http 200 from curl
exitifnothttp200() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${output}" -ne "200" ]; then
    printf "fatal command:\n%s\nrc:\n%s\noutput:\n%s\n" "$*" "${rc}" "${output}" >&2
    exit "${rc}"
  fi
}

returnoncurlfailure() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -gt 0 ]; then
    printf "command:\n%s\nrc:\n%s\noutput:\n%s\n" "$*" "${rc}" "${output}" >&2
    return "${rc}"
  fi
}

returnifnothttp200() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${output}" -ne "200" ]; then
    printf "fatal command:\n%s\nrc:\n%s\noutput:\n%s\n" "$*" "${rc}" "${output}" >&2
    return "${rc}"
  fi
}

# Exit if curl didn't get 0 or http 200
curlfatal() {
  exitoncurlfailure "$@"
  exitifnothttp200 "$@"
}

# return if curl didn't get 0 or http 200 for loops
curlretry() {
  returnoncurlfailure "$@"
  returnifnothttp200 "$@"
}

# Echo out the command that was called with all the info we need.
echocommand() {
  rc="${1}"
  shift
  output="${1}"
  shift
  printf "info: %s\nrc = %s\noutput = %s\n" "$*" "${rc}" "${output}"
}

printcurloutputonok() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -eq 0 ]; then
    printf "%s" "${output}"
  fi
}

# Note on the function names when not run under shellspec the name is sutCOMMAND otherwise its command
#
# The eval for that can't be avoided.

# Helper functions to reduce the amount of args we pass in on each curl/jq call,
# note we are calling whatever command -v curl/jq/etc.. found directly to avoid
# recursion. For now just jamming stderr and stdout into the response. Future
# work will separate them back out. Limited time to do that right.
#
# And being super opinionated for now the assumption is curl is returning the http
# return code not the body of data. Callers that care about a body response will
# need to use -o filename and handle/use that at their discretion.

# TODO: this copy/paste if hack is mostly as I can't find a great way to unit
# test this and work normally so for now a hack. Humans get to make sure if/else
# are in sync for now.
#
# If you can't see the difference its curl vs ${CURL} curl raw is for shellspec to intercept
# Probably an eval would fix it but thats a future problem.
if [ "${__SOURCED__:+sut}" = "sut" ]; then
  sutcurl() {
    if [ $# -eq 0 ]; then
      curl
    elif [ ! -t 0 ]; then
      curl "$@" < /dev/stdin
      return $?
    fi

    hookcurlentry "curl" "$@"
    output=$(curl --write-out "%{http_code}" --silent --insecure "$@" 2>&1)
    rc=$?
    hookcurl "${rc}" "${output}" "curl" "$@"
    hookcurlexit "${rc}" "${output}" "curl" "$@"
    return "${rc}"
  }
else
  CURL=${CURL:-curl}
  CURL=$(command -v "${CURL}")

  curl() {
    if [ $# -eq 0 ]; then
      ${CURL}
    elif [ ! -t 0 ]; then
      ${CURL} "$@" < /dev/stdin
      return $?
    fi

    hookcurlentry "curl" "$@"
    # Use long args here not short
    # TODO: env arg to control these default vars? Future work.
    output=$(${CURL} --write-out "%{http_code}" --silent --insecure "$@" 2>&1)
    rc=$?
    hookcurl "${rc}" "${output}" "curl" "$@"
    hookcurlexit "${rc}" "${output}" "curl" "$@"
    return "${rc}"
  }
fi

# For testing reasons we can't have curl be the function name too an intercept the curl call in shellspec
#
# Wrappers around wrappers to simplify call sites a little, no get as that is
# curl() {
#   _curl "$@"
# }

# the default for curl.
put() {
  curl --request PUT "$@"
}

post() {
  curl --request POST "$@"
}

delete() {
  curl --request DELETE "$@"
}

# Used by the jq wrapper to allow logging of args on function start or to
# control how that function behaves.
JQENTRYFN=${JQENTRYFN-}

hookjqentry() {
  if [ -n "${JQENTRYFN}" ]; then
    "${JQENTRYFN}" "$@"
  fi
}

# Same hook jq wrapper function exit and let it handle any decisions
JQEXITFN=${JQEXITFN-}

hookjqexit() {
  if [ -n "${JQEXITFN}" ]; then
    "${JQEXITFN}" "$@"
  fi
}

# For now default will be output what jq did when not under test
if [ "${__SOURCED__:+sut}" != "sut" ]; then
  JQFN=${JQFN-printjqoutputonok}
else
  JQFN=${JQFN-}
fi

hookjq() {
  if [ -n "${JQFN}" ]; then
    "${JQFN}" "$@"
  fi
}

# For now default will be to fail if jq could not parse whatever file it had
if [ "${__SOURCED__:+sut}" != "sut" ]; then
  JQTESTFAILFN=${JQTESTFAILFN-jqfatal}
else
  JQTESTFAILFN=${JQTESTFAILFN-}
fi

hookjqtestfailure() {
  if [ -n "${JQTESTFAILFN}" ]; then
    "${JQTESTFAILFN}" "$@"
  fi
}

# Dump out whatever jq would if the return code is 0
printjqoutputonok() {
  rc="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -eq 0 ]; then
    printf "%s" "${output}"
  fi
}

# exit if jq test failed only, if jq failed thats a different thing.
jqfatal() {
  rc="${1}"
  shift
  file="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -gt 0 ]; then
    printf "command:\n%s\nrc: %s\noutput: %s\nfile %s content:\n%s\n" "$*" "${rc}" "${output}" "${file}" "$(cat ${file})" >&2
    exit "${rc}"
  fi
}

jqretry() {
  rc="${1}"
  shift
  file="${1}"
  shift
  output="${1}"
  shift
  if [ "${rc}" -gt 0 ]; then
    printf "command:\n%s\nrc: %s\noutput: %s\nfile %s content:\n%s\n" "$*" "${rc}" "${output}" "${file}" "$(cat ${file})" >&2
    return "${rc}"
  fi
}

# This wrapper intentionally expects the final arg to be a file used for input.
#
# This way we can call jq to parse it before we run jq with all the args, if
# that fails then we can dump out information to the caller or call site.
#
# Operational approach is to simply run jq once against the final arg.
#
# This is to establish: is the input given valid json or not?
#
# If jq cannot parse the files data the hook functions are responsible for
# acting upon that or not to decide if something should exit or not.
if [ "${__SOURCED__:+sut}" = "sut" ]; then
  sutjq() {
    if [ $# -eq 0 ]; then
      jq
    elif [ ! -t 0 ]; then
      jq "$@" < /dev/stdin
      return $?
    fi

    hookjqentry "jq" "$@"

    # Portable way to get last arg to the fn which we expect to be a file
    #shellcheck disable=SC1083
    eval file=\${$#}

    #shellcheck disable=SC2154
    testoutput=$(jq < "${file}" 2>&1)
    rc=$?

    # Callers decide if this is return worthy or not
    if [ "${rc}" -gt 0 ]; then
      if ! hookjqtestfailure "${rc}" "${file}" "${testoutput}" "jq" "$@"; then
        return "${rc}"
      fi
    fi

    output=$(jq "$@" 2>&1)
    rc=$?
    hookjq "${rc}" "${output}" "jq" "$@"
    hookjqexit "${rc}" "${output}" "jq" "$@"
    return "${rc}"
  }
else
  JQ=${JQ:-jq}
  JQ=$(command -v "${JQ}")

  jq() {
    if [ $# -eq 0 ]; then
      ${JQ}
    elif [ ! -t 0 ]; then
      ${JQ} "$@" < /dev/stdin
      return $?
    fi

    hookjqentry "jq" "$@"

    # Portable way to get last arg to the fn which we expect to be a file
    #shellcheck disable=SC1083
    eval file=\${$#}

    #shellcheck disable=SC2154
    testoutput=$(${JQ} < "${file}" 2>&1)
    rc=$?

    # Callers decide if this is return worthy or not
    if [ "${rc}" -gt 0 ]; then
      if ! hookjqtestfailure "${rc}" "${file}" "${testoutput}" "jq" "$@"; then
        return "${rc}"
      fi
    fi

    output=$(${JQ} "$@" 2>&1)
    rc=$?
    hookjq "${rc}" "${output}" "jq" "$@"
    hookjqexit "${rc}" "${output}" "jq" "$@"
    return "${rc}"
  }
fi
