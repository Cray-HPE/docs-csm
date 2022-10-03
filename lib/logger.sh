#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
#
# Common logging library for posix shells.
#
# Note: on zsh you'll want to use emulate sh when importing as this depends on
# the default word split behavior.
#
# Follow RFC 5424/syslog for log levels/behavior.
#
# Ref: https://datatracker.ietf.org/doc/html/rfc5424
#
# Numerical  Severity             Meaning
#   Code
#
#    0       Emergency          : system is unusable
#    1       Alert              : action must be taken immediately
#    2       Critical           : critical conditions
#    3       Error              : error conditions
#    4       Warning            : warning conditions
#    5       Notice             : normal but significant condition
#    6       Informational      : informational messages
#    7       Debug              : debug-level messages

# LVL     0     1     2    3     4    5      6    7
SEVERITY="EMERG ALERT CRIT ERROR WARN NOTICE INFO DEBUG"

# Default log level is warn unless someone chooses a higher/lower level
LOG_LEVEL=${LOG_LEVEL:-warn}

# Basically get the index for the SEVERITY value, nothing special
sevtolvl() {
  lvl=$1
  sev=$(echo "${lvl}" | tr '[:lower:]' '[:upper:]')
  idx=0
  for s in $SEVERITY; do
    if [ "${sev}" = "${s}" ]; then
      break
    fi
    idx=$((idx + 1))
  done
  return $idx
}

# Print out ^^^
log_state() {
  # No amount of quoting will nuke this non complaint on sevtolvl
  #shellcheck disable=SC2046
  printf "LOG_LEVEL=%s\nLOG_LEVEL_IDX=%s\n" "${LOG_SEV}" $(sevtolvl "${LOG_LEVEL}")
}

# General logging function
#
# Example calls:
# log ERROR message with whatever
# log error message with whatever
# error message with whatever
log() {
  level=$1
  shift

  sev=$(echo "${level}" | tr '[:lower:]' '[:upper:]')
  lc=$(echo "${level}" | tr '[:upper:]' '[:lower:]')

  sevtolvl "${sev}"
  lhs=$?
  sevtolvl "${LOG_LEVEL}"
  rhs=$?
  if [ $lhs -le $rhs ]; then
    # Note: do not switch $* to $@ here, in spaces/args with printf lie dragons.
    # (it split lines probably off IFS dunno for now, future me problem)
    #
    # For now dump to stderr
    printf "%s: %s\n" "${lc}" "$*" >&2
  fi
}

# Helper functions for typing less log ... statements
emerg() {
  log emerg "$@"
}

alert() {
  log alert "$@"
}

crit() {
  log crit "$@"
}

error() {
  log error "$@"
}

warn() {
  log warn "$@"
}

notice() {
  log notice "$@"
}

info() {
  log info "$@"
}

debug() {
  log debug "$@"
}

# And more internal "ignore LOG_LEVEL" versions.
_emerg() {
  LOG_LEVEL=emerg log emerg "$@"
}

_alert() {
  LOG_LEVEL=alert log alert "$@"
}

_crit() {
  LOG_LEVEL=crit log crit "$@"
}

_error() {
  LOG_LEVEL=error log error "$@"
}

_warn() {
  LOG_LEVEL=warn log warn "$@"
}

_notice() {
  LOG_LEVEL=notice log notice "$@"
}

_info() {
  LOG_LEVEL=info log info "$@"
}

_debug() {
  LOG_LEVEL=debug log debug "$@"
}
