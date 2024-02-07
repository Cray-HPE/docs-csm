#!/bin/bash
#
# MIT License
#
# (C) Copyright 223 Hewlett Packard Enterprise Development LP
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

# Create k8s topology zone(s) with the given k8s ncn nodes
rack_id=1
while true; do
    read -p "Do you want to create new k8 zone? " yn
    case $yn in
        [Yy]* )
	        echo "Enter ncn nodes to be zoned under rack-$rack_id:"
		read ncn_nodes
		echo "$ncn_nodes"
		kubectl label nodes $ncn_nodes topology.kubernetes.io/zone=rack-$rack_id --overwrite
		rack_id=$((rack_id +1)) 
		continue;;
        [Nn]* ) exit;;
        * ) echo "Do you want to create another k8 zone? Please answer yes or no.";;
    esac
done
