#!/system/bin/sh
#
# Test for version N5110-2.2 alpha1
# -> disabled charge rate functionality

# define basic kernel configuration
# *********************************************************

# Kernel type
	# KERNEL="SAM1"		# Samsung old bootanimation / zram concept
	KERNEL="SAM2"		# Samsung new bootanimation / zram concept
	# KERNEL="CM"		# Cyanogenmod+Omni

# path to internal sd memory
	# SD_PATH="/data/media"			# JB 4.1
	 SD_PATH="/data/media/0"		# JB 4.2, 4.3, 4.4

# block devices
	SYSTEM_DEVICE="/dev/block/mmcblk0p9"
	CACHE_DEVICE="/dev/block/mmcblk0p8"
	DATA_DEVICE="/dev/block/mmcblk0p12"

# *********************************************************


# define file paths
BOEFFLA_DATA_PATH="$SD_PATH/boeffla-kernel-data"
BOEFFLA_LOGFILE="$BOEFFLA_DATA_PATH/boeffla-kernel.log"
BOEFFLA_STARTCONFIG="/data/.boeffla/startconfig"
BOEFFLA_STARTCONFIG_DONE="/data/.boeffla/startconfig_done"
CWM_RESET_ZIP="boeffla-config-reset-v2.zip"
INITD_ENABLER="/data/.boeffla/enable-initd"
BUSYBOX_ENABLER="/data/.boeffla/enable-busybox"
FRANDOM_ENABLER="/data/.boeffla/enable-frandom"


# If not yet exists, create a boeffla-kernel-data folder on sdcard 
# which is used for many purposes (set permissions and owners correctly)
	if [ ! -d "$BOEFFLA_DATA_PATH" ] ; then
		/sbin/busybox mkdir $BOEFFLA_DATA_PATH
		/sbin/busybox chmod 775 $BOEFFLA_DATA_PATH
		/sbin/busybox chown 1023:1023 $BOEFFLA_DATA_PATH
	fi

# maintain log file history
	rm $BOEFFLA_LOGFILE.3
	mv $BOEFFLA_LOGFILE.2 $BOEFFLA_LOGFILE.3
	mv $BOEFFLA_LOGFILE.1 $BOEFFLA_LOGFILE.2
	mv $BOEFFLA_LOGFILE $BOEFFLA_LOGFILE.1

# Initialize the log file (chmod to make it readable also via /sdcard link)
	echo $(date) Boeffla-Kernel initialisation started > $BOEFFLA_LOGFILE
	/sbin/busybox chmod 666 $BOEFFLA_LOGFILE
	/sbin/busybox cat /proc/version >> $BOEFFLA_LOGFILE
	echo "=========================" >> $BOEFFLA_LOGFILE
	/sbin/busybox grep ro.build.version /system/build.prop >> $BOEFFLA_LOGFILE
	echo "=========================" >> $BOEFFLA_LOGFILE

# Activate frandom entropy generator if configured
	if [ -f $FRANDOM_ENABLER ]; then
		echo $(date) "Frandom entropy generator activation requested" >> $BOEFFLA_LOGFILE
		/sbin/busybox insmod /lib/modules/frandom.ko
		/sbin/busybox insmod /system/lib/modules/frandom.ko

		if [ ! -e /dev/urandom.ORIG ] && [ ! -e /dev/urandom.orig ] && [ ! -e /dev/urandom.ori ]; then
			/sbin/busybox touch /dev/urandom.MOD
			/sbin/busybox touch /dev/random.MOD
			/sbin/busybox mv /dev/urandom /dev/urandom.ORIG
			/sbin/busybox ln /dev/erandom /dev/urandom
			/sbin/busybox busybox chmod 644 /dev/urandom
			/sbin/busybox mv /dev/random /dev/random.ORIG
			/sbin/busybox ln /dev/erandom /dev/random
			/sbin/busybox busybox chmod 644 /dev/random
			/sbin/busybox sleep 0.5s
			/sbin/busybox sync
			echo $(date) "Frandom entropy generator activated" >> $BOEFFLA_LOGFILE
		fi
	fi

# Install busybox applet symlinks to /system/xbin if enabled,
# otherwise only install mount/umount/top symlinks
	mount -o remount,rw -t ext4 $SYSTEM_DEVICE /system
	if [ -f $BUSYBOX_ENABLER ]; then
		/sbin/busybox --install -s /system/xbin
		echo $(date) "Busybox applet symlinks installed to /system/xbin" >> $BOEFFLA_LOGFILE
	else
		/sbin/busybox ln -s /sbin/busybox /system/xbin/mount
		/sbin/busybox ln -s /sbin/busybox /system/xbin/umount
		/sbin/busybox ln -s /sbin/busybox /system/xbin/top
		echo $(date) "Mount/umount/top applet symlinks installed to /system/xbin" >> $BOEFFLA_LOGFILE
	
	fi
	mount -o remount,ro -t ext4 $SYSTEM_DEVICE /system
		
# Correct /sbin and /res directory and file permissions
	mount -o remount,rw rootfs /

	# change permissions of /sbin folder and scripts in /res/bc
	/sbin/busybox chmod -R 755 /sbin
	/sbin/busybox chmod 755 /res/bc/*

	/sbin/busybox sync
	mount -o remount,ro rootfs /

# remove any obsolete Boeffla-Config V2 startconfig done file
/sbin/busybox rm -f $BOEFFLA_STARTCONFIG_DONE

# Custom boot animation support only for Samsung Kernels,
# boeffla sound change delay changed only for Samsung Kernels
	if [ "SAM1" == "$KERNEL" ]; then
	
		# check whether custom boot animation is available to be played
		if [ -f /data/local/bootanimation.zip ] || [ -f /system/media/bootanimation.zip ]; then
				echo $(date) Playing custom boot animation >> $BOEFFLA_LOGFILE
				/system/bin/bootanimation &
		else
				echo $(date) Playing Samsung stock boot animation >> $BOEFFLA_LOGFILE
				/system/bin/samsungani &
		fi

		# set boeffla sound change delay to 200 ms
		echo "200000" > /sys/class/misc/boeffla_sound/change_delay
		echo $(date) Boeffla-Sound change delay set to 200 ms >> $BOEFFLA_LOGFILE
	fi

	if [ "SAM2" == "$KERNEL" ]; then
	
		# check whether custom boot animation is available to be played
		if [ -f /data/local/bootanimation.zip ] || [ -f /system/media/bootanimation.zip ]; then
				echo $(date) Playing custom boot animation >> $BOEFFLA_LOGFILE
				/sbin/bootanimation &
		else
				echo $(date) Playing Samsung stock boot animation >> $BOEFFLA_LOGFILE
				/system/bin/bootanimation &
		fi

		# set boeffla sound change delay to 200 ms
		echo "200000" > /sys/class/misc/boeffla_sound/change_delay
		echo $(date) Boeffla-Sound change delay set to 200 ms >> $BOEFFLA_LOGFILE
	fi

# Set the options which change the stock kernel defaults
# to Boeffla-Kernel defaults

	echo $(date) Applying Boeffla-Kernel default settings >> $BOEFFLA_LOGFILE

	# Ext4 tweaks default to on
	sync
	mount -o remount,commit=20,noatime $CACHE_DEVICE /cache
	sync
	mount -o remount,commit=20,noatime $DATA_DEVICE /data
	sync
	echo $(date) Ext4 tweaks applied >> $BOEFFLA_LOGFILE

	# Sdcard buffer tweaks default to 256 kb
	echo 256 > /sys/block/mmcblk0/bdi/read_ahead_kb
	echo $(date) "SDcard buffer tweaks (256 kb) applied for internal sd memory" >> $BOEFFLA_LOGFILE
	echo 256 > /sys/block/mmcblk1/bdi/read_ahead_kb
	echo $(date) "SDcard buffer tweaks (256 kb) applied for external sd memory" >> $BOEFFLA_LOGFILE

	# AC charging rate defaults defaults to 1900 mA
#	echo "1900" > /sys/kernel/charge_levels/charge_level_ac
#	echo $(date) "AC charge rate set to 1900 mA" >> $BOEFFLA_LOGFILE

# init.d support, only if enabled in settings or file in data folder
# (zipalign scripts will not be executed as only exception)
	if [ "CM" != "$KERNEL" ] || [ -f $INITD_ENABLER ] ; then
		echo $(date) Execute init.d scripts start >> $BOEFFLA_LOGFILE
		if cd /system/etc/init.d >/dev/null 2>&1 ; then
			for file in * ; do
				if ! cat "$file" >/dev/null 2>&1 ; then continue ; fi
				if [[ "$file" == *zipalign* ]]; then continue ; fi
				echo $(date) init.d file $file started >> $BOEFFLA_LOGFILE
				/system/bin/sh "$file"
				echo $(date) init.d file $file executed >> $BOEFFLA_LOGFILE
			done
		fi
		echo $(date) Finished executing init.d scripts >> $BOEFFLA_LOGFILE
	else
		echo $(date) init.d script handling by kernel disabled >> $BOEFFLA_LOGFILE
	fi

# Now wait for the rom to finish booting up
# (by checking for the android acore process)
	echo $(date) Checking for Rom boot trigger... >> $BOEFFLA_LOGFILE
	while ! /sbin/busybox pgrep com.android.systemui ; do
	  /sbin/busybox sleep 1
	done
	echo $(date) Rom boot trigger detected, waiting a few more seconds... >> $BOEFFLA_LOGFILE
	/sbin/busybox sleep 10

# Play sound for Boeffla-Sound compatibility
	echo $(date) Initialize sound system... >> $BOEFFLA_LOGFILE
	/sbin/tinyplay /res/misc/silence.wav -D 0 -d 0 -p 880

# Disable Samsung standard zRam implementation if new concept Samsung kernel
	if [ "SAM2" == "$KERNEL" ]; then
		busybox swapoff /dev/block/zram0
		echo "1" > /sys/block/zram0/reset
		echo "0" > /sys/block/zram0/disksize
	fi

# Interaction with Boeffla-Config app V2
	# save original stock values for selected parameters
	cat /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table > /dev/bk_orig_cpu_voltage
	cat /sys/class/misc/gpu_clock_control/gpu_control > /dev/bk_orig_gpu_clock
	cat /sys/class/misc/gpu_voltage_control/gpu_control > /dev/bk_orig_gpu_voltage
#	cat /sys/kernel/charge_levels/charge_level_ac > /dev/bk_orig_charge_level_ac
#	cat /sys/kernel/charge_levels/charge_level_usb > /dev/bk_orig_charge_level_usb
#	cat /sys/kernel/charge_levels/charge_level_wireless > /dev/bk_orig_charge_level_wireless
	cat /sys/module/lowmemorykiller/parameters/minfree > /dev/bk_orig_minfree
	/sbin/busybox lsmod > /dev/bk_orig_modules

	# if there is a startconfig placed by Boeffla-Config V2 app, execute it
	if [ -f $BOEFFLA_STARTCONFIG ]; then
		echo $(date) "Startup configuration found:"  >> $BOEFFLA_LOGFILE
		cat $BOEFFLA_STARTCONFIG >> $BOEFFLA_LOGFILE
		. $BOEFFLA_STARTCONFIG
		echo $(date) Startup configuration applied  >> $BOEFFLA_LOGFILE
	fi
	
# Turn off debugging for certain modules
	echo 0 > /sys/module/ump/parameters/ump_debug_level
	echo 0 > /sys/module/mali/parameters/mali_debug_level
	echo 0 > /sys/module/kernel/parameters/initcall_debug
	echo 0 > /sys/module/lowmemorykiller/parameters/debug_level
	echo 0 > /sys/module/earlysuspend/parameters/debug_mask
	echo 0 > /sys/module/alarm/parameters/debug_mask
	echo 0 > /sys/module/alarm_dev/parameters/debug_mask
	echo 0 > /sys/module/binder/parameters/debug_mask
	echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask

# Auto root support
	if [ -f $SD_PATH/autoroot ]; then

		echo $(date) Auto root is enabled >> $BOEFFLA_LOGFILE

		mount -o remount,rw -t ext4 $SYSTEM_DEVICE /system

		/sbin/busybox mkdir /system/bin/.ext
		/sbin/busybox cp /res/misc/su /system/xbin/su
		/sbin/busybox cp /res/misc/su /system/xbin/daemonsu
		/sbin/busybox cp /res/misc/su /system/bin/.ext/.su
		/sbin/busybox cp /res/misc/install-recovery.sh /system/etc/install-recovery.sh
		/sbin/busybox echo /system/etc/.installed_su_daemon
		
		/sbin/busybox chown 0.0 /system/bin/.ext
		/sbin/busybox chmod 0777 /system/bin/.ext
		/sbin/busybox chown 0.0 /system/xbin/su
		/sbin/busybox chmod 6755 /system/xbin/su
		/sbin/busybox chown 0.0 /system/xbin/daemonsu
		/sbin/busybox chmod 6755 /system/xbin/daemonsu
		/sbin/busybox chown 0.0 /system/bin/.ext/.su
		/sbin/busybox chmod 6755 /system/bin/.ext/.su
		/sbin/busybox chown 0.0 /system/etc/install-recovery.sh
		/sbin/busybox chmod 0755 /system/etc/install-recovery.sh
		/sbin/busybox chown 0.0 /system/etc/.installed_su_daemon
		/sbin/busybox chmod 0644 /system/etc/.installed_su_daemon

		/system/bin/sh /system/etc/install-recovery.sh

		mount -o remount,ro -t ext4 $SYSTEM_DEVICE /system
		echo $(date) Auto root: su installed >> $BOEFFLA_LOGFILE

		rm $SD_PATH/autoroot
	fi

# EFS backup
	EFS_BACKUP_INT="$BOEFFLA_DATA_PATH/efs.tar.gz"
	EFS_BACKUP_EXT="/storage/extSdCard/efs.tar.gz"

	if [ ! -f $EFS_BACKUP_INT ]; then

		cd /efs
		/sbin/busybox tar cvz -f $EFS_BACKUP_INT .
		/sbin/busybox chmod 666 $EFS_BACKUP_INT

		/sbin/busybox cp $EFS_BACKUP_INT $EFS_BACKUP_EXT
		
		echo $(date) EFS Backup: Not found, now created one >> $BOEFFLA_LOGFILE
	fi

# Copy reset cwm zip in boeffla-kernel-data folder
	CWM_RESET_ZIP_SOURCE="/res/misc/$CWM_RESET_ZIP"
	CWM_RESET_ZIP_TARGET="$BOEFFLA_DATA_PATH/$CWM_RESET_ZIP"

	if [ ! -f $CWM_RESET_ZIP_TARGET ]; then

		/sbin/busybox cp $CWM_RESET_ZIP_SOURCE $CWM_RESET_ZIP_TARGET
		/sbin/busybox chmod 666 $CWM_RESET_ZIP_TARGET

		echo $(date) CWM reset zip copied >> $BOEFFLA_LOGFILE
	fi

# Finished
	echo $(date) Boeffla-Kernel initialisation completed >> $BOEFFLA_LOGFILE
