#!/bin/sh
#
# Called from udev
#
# Attempt to mount any added block devices and umount any removed devices


MOUNT="/bin/mount"
PMOUNT="/usr/bin/pmount"
UMOUNT="/bin/umount"
for line in `grep -h -v ^# /etc/udev/mount.blacklist /etc/udev/mount.blacklist.d/*`
do
	if [ ` expr match "$DEVNAME" "$line" ` -gt 0 ];
	then
		logger "udev/mount.sh" "[$DEVNAME] is blacklisted, ignoring"
		exit 0
	fi
done

automount() {	
	name="`basename "$DEVNAME"`"
<<<<<<< HEAD

	! test -d "/run/media/$name" && mkdir -p "/run/media/$name"
=======
	bus="`basename "$ID_BUS"`"

	# Figure out a mount point to use
	LABEL=${ID_FS_LABEL}

	if [[ -z "${LABEL}" ]]; then
		udevadm info /dev/$name | grep -q 'mmc'
		mmc=$?
		if [ "${mmc}" -eq "0" ]; then
			if [ ! -d "/run/media/mmc" ]; then
				LABEL="mmc"
			else
				LABEL="$name"
			fi
		elif [ "${bus}" == "ata" ]; then
			udevadm info /dev/$name | grep -q 'ahci\|pci\|sata'
			internal=$?
			if [ "${internal}" -eq "0" ]; then
				LABEL="hdd"
			elif [ ! -d "/run/media/usbhdd" ]; then
				LABEL="usbhdd"
			else
				LABEL="$name"
			fi
		else
			LABEL="$name"
		fi
	fi
	! test -d "/run/media/$LABEL" && mkdir -p "/run/media/$LABEL"
>>>>>>> upstream/zeus
	# Silent util-linux's version of mounting auto
	if [ "x`readlink $MOUNT`" = "x/bin/mount.util-linux" ] ;
	then
		MOUNT="$MOUNT -o silent"
	fi
	
	# If filesystem type is vfat, change the ownership group to 'disk', and
	# grant it with  w/r/x permissions.
	case $ID_FS_TYPE in
	vfat|fat)
		MOUNT="$MOUNT -o umask=007,gid=`awk -F':' '/^disk/{print $3}' /etc/group`"
		;;
	# TODO
	*)
		;;
	esac

<<<<<<< HEAD
	if ! $MOUNT -t auto $DEVNAME "/run/media/$name"
	then
		#logger "mount.sh/automount" "$MOUNT -t auto $DEVNAME \"/run/media/$name\" failed!"
		rm_dir "/run/media/$name"
	else
		logger "mount.sh/automount" "Auto-mount of [/run/media/$name] successful"
		touch "/tmp/.automount-$name"
=======
	if ! $MOUNT -t auto $DEVNAME "/run/media/$LABEL"
	then
		#logger "mount.sh/automount" "$MOUNT -t auto $DEVNAME \"/run/media/$LABEL\" failed!"
		rm_dir "/run/media/$LABEL"
	else
		logger "mount.sh/automount" "Auto-mount of [/run/media/$LABEL] successful"
		touch "/tmp/.automount-$LABEL"
>>>>>>> upstream/zeus
	fi
}
	
rm_dir() {
	# We do not want to rm -r populated directories
	if test "`find "$1" | wc -l | tr -d " "`" -lt 2 -a -d "$1"
	then
		! test -z "$1" && rm -r "$1"
	else
		logger "mount.sh/automount" "Not removing non-empty directory [$1]"
	fi
}

# No ID_FS_TYPE for cdrom device, yet it should be mounted
name="`basename "$DEVNAME"`"
[ -e /sys/block/$name/device/media ] && media_type=`cat /sys/block/$name/device/media`

if [ "$ACTION" = "add" ] && [ -n "$DEVNAME" ] && [ -n "$ID_FS_TYPE" -o "$media_type" = "cdrom" ]; then
	if [ -x "$PMOUNT" ]; then
		$PMOUNT $DEVNAME 2> /dev/null
	elif [ -x $MOUNT ]; then
    		$MOUNT $DEVNAME 2> /dev/null
	fi
	
	# If the device isn't mounted at this point, it isn't
	# configured in fstab (note the root filesystem can show up as
	# /dev/root in /proc/mounts, so check the device number too)
	if expr $MAJOR "*" 256 + $MINOR != `stat -c %d /`; then
		grep -q "^$DEVNAME " /proc/mounts || automount
	fi
fi


if [ "$ACTION" = "remove" ] || [ "$ACTION" = "change" ] && [ -x "$UMOUNT" ] && [ -n "$DEVNAME" ]; then
	for mnt in `cat /proc/mounts | grep "$DEVNAME" | cut -f 2 -d " " `
	do
		$UMOUNT $mnt
	done
	
	# Remove empty directories from auto-mounter
	name="`basename "$DEVNAME"`"
	test -e "/tmp/.automount-$name" && rm_dir "/run/media/$name"
<<<<<<< HEAD
=======
	test -e "/tmp/.automount-$LABEL" && rm_dir "/run/media/$LABEL"
	test -e "/tmp/.automount-mmc" && rm_dir "/run/media/mmc"
	test -e "/tmp/.automount-hdd" && rm_dir "/run/media/hdd"
	test -e "/tmp/.automount-usbhdd" && rm_dir "/run/media/usbhdd"
>>>>>>> upstream/zeus
fi
