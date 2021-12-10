#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

function mark_initialized() {
  initialized_file=$1
  touch $initialized_file
}
