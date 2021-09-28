#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

