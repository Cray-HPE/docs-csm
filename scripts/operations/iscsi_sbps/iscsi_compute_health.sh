#!/bin/sh

#  MIT License
#
#  (C) Copyright 2026 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

# This script is to check health of the compute/uan nodes from iSCSI SBPS
# perspective. This is mainly used during post worker rollout.

# shellcheck disable=SC3030

OUTPUT=$(multipath -ll 2>&1)
CMD_STATUS=$?

echo "Multipath Path Health Check"
echo "==========================="

[ "$CMD_STATUS" -eq 0 ] || {
    echo "ERROR: multipath -ll command failed"
    exit 1
}

PATH_COUNT=0
FAILED=0

TMPFILE=$(mktemp) || exit 1
printf '%s\n' "$OUTPUT" > "$TMPFILE"

while IFS= read -r line
do
    DEVICE=$(printf '%s\n' "$line" | awk '
    {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^[a-zA-Z]+$/ &&
                $(i+1) ~ /^[0-9]+:[0-9]+$/ &&
                $(i+2) ~ /^(active|failed|faulty|offline|ghost|running|ready)$/) {
                print $i
                exit
            }
        }
    }')

    if [ -n "$DEVICE" ]; then
        PATH_COUNT=$((PATH_COUNT + 1))

        if printf '%s\n' "$line" | grep -q 'active ready running'; then
            echo "PASS: $DEVICE - active ready running"
        else
            echo "FAIL: $DEVICE - $line"
            FAILED=1
        fi
    fi
done < "$TMPFILE"

rm -f "$TMPFILE"

echo "==========================="
echo "Total paths checked: $PATH_COUNT"

if [ "$PATH_COUNT" -eq 0 ]; then
    echo "OVERALL RESULT: FAIL - No paths found"
    exit 1
elif [ "$FAILED" -eq 1 ]; then
    echo "OVERALL RESULT: FAIL - Faulty paths detected"
    exit 1
else
    echo "OVERALL PATH HEALTH RESULT: PASS - All paths active, ready and running"
fi

echo "                            "
echo "============================"
echo "Systemd Service Health Check"
echo "============================"

SERVICES=("iscsid.service" "multipathd.service")

FAILED=0

for SERVICE in "${SERVICES[@]}"; do

    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null)

    if [ "$STATUS" = "active" ]; then
        echo "PASS: $SERVICE is active and running"
    else
        echo "FAIL: $SERVICE is not active (Status: $STATUS)"
        FAILED=1
    fi

done

echo "============================"

if [ "$FAILED" -eq 0 ]; then
    echo "OVERALL RESULT: PASS - iscsid and multipathd services are acitve and running"
    exit 0
else
    echo "OVERALL RESULT: FAIL"
    exit 1
fi
