#!/usr/bin/env bash
set -eu
set -o pipefail

trap 'echo Cancelling $(basename "${0%.*}") ; cleanup ; exit 1' SIGINT

pit_check() {
	if [[ $HOSTNAME == *pit* ]]; then
		return 0
	else
		return 1
	fi
}

if ! eval pit_check; then
	# get the mount directory as it can vary between vintages: CSM 0.9.X uses /metal/boot, CSM 1.0 uses /metal/recovery
	BOOTRAID=$(awk '/LABEL=BOOTRAID/ {print $2}' /etc/fstab.metal)
else
	BOOTRAID=""
fi

REBOOT_NEEDED="false"

# Stuff to cleanup on exit
cleanup() {
	if ! eval pit_check; then
		if eval mount | grep "${BOOTRAID}" >/dev/null; then
			umount $BOOTRAID
		fi
	fi

	if [[ "$REBOOT_NEEDED" == "true" ]]; then
		echo "The new on-disk boot artifacts won't take effect until a restart of the machine."
	fi
}

mount_bootraid() {
	if ! eval pit_check; then
		if ! eval mount | grep "${BOOTRAID}" >/dev/null; then
			# Mount the BOOTRAID parititon
			mount -L BOOTRAID -T /etc/fstab.metal
		fi
	fi
}

expected_initrd_name() {
	# find the name the grub config expects
	expected_name=$(grep initrdefi "${BOOTRAID}"/boot/grub2/grub.cfg | awk '{print $2}' | awk -F'/' '{print $NF}')
	echo "${expected_name}"
}

check_cray_init_status() {
		if eval cray bss bootparameters list; then
		  return 0
		else
			return 1
		fi
}

get_artifact_from_s3() {
	local artifact="${1}"
	local kernel=""
	local initrd=""

	mount_bootraid

	if ! eval check_cray_init_status >/dev/null 2>&1; then
		echo -n "\nPlease run 'cray init'"
		exit 1
	fi

	if [[ "$(basename ${artifact})" == *kernel* ]]; then

		# Check the path listed in s3 based on this xname
		kernel=$(cray bss bootparameters list --hosts "$(cat /etc/cray/xname)" | awk -F '"' '/kernel = / {print $2}')

		echo "Getting $(basename ${artifact}) from s3 (http://rgw-vip.nmn/${kernel/s3:\/\/})..."
		curl -o ${artifact} http://rgw-vip.nmn/"${kernel/s3:\/\/}"

	# Do the same for the initrd
	elif [[ "$(basename ${artifact})" == *initrd* ]]; then

		initrd=$(cray bss bootparameters list --hosts "$(cat /etc/cray/xname)" | awk -F '"' '/initrd = / {print $2}')

		echo "Getting $(basename ${artifact}) from s3 (http://rgw-vip.nmn/${initrd/s3:\/\/})..."
		curl -o ${artifact} http://rgw-vip.nmn/"${initrd/s3:\/\/}"

	fi

	REBOOT_NEEDED="true"
}

check_boot_artifact() {
	local artifact="$1"
	# check if the filesize is bigger than 217 (that is the size of an XML error message from s3)
	# or check if this is a filetype we expect for a kernel or initrd
	if ! [[ "$(stat --format=%s $f)" -gt 217 ]] || ! [[ "$(file --brief --mime-type $f)" == application/octet-stream ]]; then
		echo -e "\n${f} size is too small or not an expected file type ($(stat --format=%s $f):$(file --brief --mime-type $f))"
		return 1
	else
		return 0
	fi
}

# mount the raid
mount_bootraid

# for each of our boot artifacts on the system
# /run/initramfs/live/LiveOS/kernel /run/initramfs/live/LiveOS/initrd.img.xz
for f in "${BOOTRAID}/boot/kernel" "${BOOTRAID}/boot/initrd.img.xz"
do
	printf "Examining ${f}..."

	if eval pit_check; then
		echo -e "\n$(basename ${f}) not used on PIT."
		continue
	fi

	if [[ -f "${f}" ]]; then

		# if the file is no good
		if ! eval check_boot_artifact "${f}"; then
			# Remove the problematic file
			rm -f "${f}"

			# Get a good one from s3
			get_artifact_from_s3 "${f}"

			# Modify the filename if grub is expecting something else
			if [[ $(basename ${f}) == *initrd* ]] && \
					[[ $(basename ${f}) != $(expected_initrd_name) ]]; then
					echo mv "${f}" "$(dirname ${f})/$(expected_initrd_name)"
			fi

		else

			printf "$(basename ${f}) is OK.\n"

		fi

	else

		echo "$(basename ${f}) not found in BOOTRAID."

		# Get a good one from s3
		get_artifact_from_s3 "${f}"

	fi
done

cleanup