#!/bin/bash
# Copyright 2021-2022 Hewlett Packard Enterprise Development LP

error=0
printf "=============== Linting \” (https://www.compart.com/en/unicode/U+201D) ... \n"
grep -n -R \” *.md && echo >&2 'Malformed quotes detected (bad: ” vs. good: ").' && error=1
[ $error = 1 ] && echo '^FAILED'


printf "+++++++++++++++ ... OK\n" && exit 0
