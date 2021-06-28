#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

kubectl -n services delete pvc gitea-vcs-data-claim --wait=false
