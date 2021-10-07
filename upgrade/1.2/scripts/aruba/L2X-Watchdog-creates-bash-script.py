# -*- coding: utf-8 -*-
#
# (c) Copyright 2018-2019 Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.

Manifest = {
    'Name': 'L2X-Watchdog',
    'Description': 'Monitor for L2 MAC learning system process '
                   'and attempt to restart to recover system health.',
    'Version': '1.0',
    'TargetSoftwareVersion': '10.04',
    'Author': 'Aruba Networks - CEE Team'

}

class Policy(NAE):
    def __init__(self):
        self.r1 = Rule("L2X Watchdog")
        self.r1.condition("every 60 seconds")
        self.r1.action(self.action_upon_boot)
        self.variables['configured'] = '0'

    def action_upon_boot(self, event):
        if int(self.variables['configured']) == 1:
            ActionShell("sudo /tmp/topbcm.sh")
        else:
            self.writeScript()

    def writeScript (self):
        self.variables['configured'] = '1'
        # The following ActionShell will do the following:
        # 1. create a temporary file for
        # 2. install a bash script to the switch which used
        #    for creating the watchdog for BCML2X
        ActionShell(
            '''echo "#!/bin/bash" > /tmp/topbcm.sh \n'''
            '''echo "TOP=\`top -w 512 -b -n 1 -o %CPU -H | grep bcmL2X\`" >> /tmp/topbcm.sh\n'''
            '''echo "if [[ \$TOP ]]; then" >> /tmp/topbcm.sh\n'''
            '''echo "    :" >> /tmp/topbcm.sh\n'''
            '''echo "else" >> /tmp/topbcm.sh\n'''
            '''echo "    echo \`date\`" >> /tmp/topbcm.sh\n'''
            '''echo "    echo 'BCML2x PID not found'" >> /tmp/topbcm.sh\n'''
            '''echo "    echo 'Executing bcmL2X.0 recovery...'" >> /tmp/topbcm.sh\n'''
            '''echo "    logger "BCML2X has quit unexpectedly, attempting to restart..."" >> /tmp/topbcm.sh\n'''
            '''echo "    { echo "l2 watch start"; sleep 1; echo "l2 watch stop"; sleep 1; } | /usr/bin/start_bcm_shell" >> /tmp/topbcm.sh\n'''
            '''echo "fi" >> /tmp/topbcm.sh\n'''
            '''chmod 755 /tmp/topbcm.sh \n''')






