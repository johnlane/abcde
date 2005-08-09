#!/bin/bash
# TODO:
#	Add paranoia.
#	Fix logger messages.
#	Add periodic/startup file/directory checks.
#	Auto check of cd drive perms.

echo "Autorip 0.1.3 started."

# Set script local variables

# FREEMIN
# The minimum free space to have on the local TMP directory.
FREEMIN="750"

# TIMEOUT
# The timeout, in seconds (approx), for the cd-tray to be sucked back 
# in if it's not in already, this isn't exact, as a cycle is a bit more
# then a second, but it comes out to about 3 hours.
TIMEOUT=21600


# CDROM
# The cd-rom device to be used.
CDROM="/dev/cdroms/cdrom1"

# BASE
# The folder to be used for all of the actions
BASE="`pwd`"

# DONE
# The destination of the encoded files.
DONE="$BASE/done"

# TMP
# Defaukt temporary directory.
TMP="$BASE/tmp"

# REMTEMP
# Remote temporary directory. (currently unused)
REMTEMP="$BASE/remtmp"

# LOCTEMP
# Local temporary directory.
LOCTEMP="$BASE/tmp"

# LOGDEST
# The syslog facility to use for logging purposes.
LOGDEST="local3"


# Oher variables (Do not set)

# LASTSTART - Last CD in the drive that was encoded.
# LASTDONE - Last CD that was finished encoding.
# TIME	 - Approximately how many seconds have passed without having a cd in the drive.
# CURRCD - This variable obtains the discid of whatever's in the cd drive.
# REENC	 - The disc-id of an already encoded disc put into the drive.
# PROCESS - A short feild of the DISCID that's used for keeping track of running encodes.
# PROCDIR - The working directory of a process.
# DISCNAME - A process local variable that's just the name of the finished disc.
# DONELOCK - A timer for waiting for an add to the DB. Wait no more than 60 seconds.

LASTSTART=""
TIME=0
REENC=0

# Reset the status of running.

echo 0 > "$BASE/lib/stop"

rm -r "$TMP"
mkdir "$TMP"

main ()
{
	getcurcd
	
	# If the cd in the drive is currently being encoded, don't try to encode it.
	# Just sleep for 120 seconds and try again later.	

	if [ "$CURCD" != "" ] && [ "$CURCD" = "$LASTSTART" ]
	then	
		sleep 120
		TIME=0
		return 0
		
	# If the CD isn't the same as the last one started, and cdparanoia is running
	# Assume shit has hit the fan and kill it to end the current process.
	# The process will die on it's own.
	
	elif [ "$CURCD" != "$LASTSTART" ] && [ "$(ps --no-heading -C cdparanoia)" != "" ]
	then

		logger -p $LOGDEST.info "Error ($LASTSTART): Disc removed while encoding!"						
		killall -KILL cdparanoia
		
		# Reset the last start, because it wasn't.
		
		LASTSTART=""
		
		sleep 10
		return 0
	
	# If there's nothing in the drive, and there's no timeout yet, increase.
	# If something was in the drive, the function would return without encoding it.
	
	elif [ $TIME -lt $TIMEOUT ] && [ "$CURCD" = "" ]
	then
	 	TIME=$(($TIME+15))
		sleep 15
		return 0
	
	# If the cd has been sticking out for the timeout period (which is approx three hours).
	# Suck it back in. This could be used to send a message to the domain, or cause beeping.	
		
	elif [ $TIME -ge $TIMEOUT ]
	then
		timeout
		
		TIME=0
		
		return 0
	fi

	# Eject the CD if the last CD processed is sucked (or put) back in.	


	# If there is a cd in the drive
	# Do not encode the last CD to go through the encoding process.
	# This would cause the same CD to be re-re-rencoded if left in the drive
	# for too long.

	if [ "$CURCD" != "" ] && [ "$CURCD" != "$(< "$BASE/lib/LASTDONE")" ] &! [ -d "$TMP/$(echo $CURCD | cut -f 1 -d \ )" ]
	then
		
		# If the cd in the drive was already encoded, set reenc to the disc-id. If the user puts the
		# disc back in the drive, it will re-encode. If it's different, REENC won't matter.
		
		if [ "`grep "$CURCD" $BASE/lib/done.db`" = "" ] || [ "$REENC" = "$CURCD" ] 
		then
			until [ "$(($(stat -f "$TMP" --format=%a)*4096/1024/1024))" -gt "$FREEMIN" ]
			do
				sleep 120
			done
		
			LASTSTART=$CURCD
			cdenc &
			REENC=$CURCD
			
		else
			eject $CDROM
			beep -r 3
			REENC="$CURCD"
			return 0
		fi
	fi
}

getcurcd()
{
	# Check for a cd. If cd-discid exits successfully, then set the variable.
	# If it exits with a 0 (backwards, I know), then blank it.

	if $(cd-discid $CDROM > /dev/null 2>&1)

	then
		CURCD=$(cd-discid $CDROM 2>&1)
	else
		CURCD=""
	fi
	return 0
}



timeout()
{
	eject -t $CDROM && getcurcd

	# If the cd was the last done, assume we timed out.

	if [ "$CURCD" = "$(< "$BASE/lib/LASTDONE")" ] 
	then
		logger -p $LOGDEST.error "CD Left (or put back) in drive."
		eject $CDROM
		beep -r 4
		return 0
	fi

	return 0
}


# CD Encoder function. The workhorse.
# Note: Only call when CD is in drive, else exit.

cdenc ()
{	
	# Check to make sure the cd wasn't changed or removed.
		
	if [ "$(cd-discid $CDROM 2>&1)" != "$CURCD" ]
	then
		return 0
	fi
	
	# Set this process's id.
	
	local PROCESS="$(echo $CURCD | cut -f 1 -d \ )"
	local THISDISC="$CURCD"
	local PROCDIR="$TMP/$PROCESS"
	local DONELOCK=0

	# Make a work folder
	
	rm -fr "$PROCDIR"
	mkdir "$PROCDIR"
	cd "$PROCDIR"

	
	# Okay, abcde has a bug where it tries to rip data cd's. But the version that fixes it itself has
	# even more. So instead of trying to install the new version, which doesn't work, we use a command
	# similar to the one ABCDE uses to determine the number of valid tracks (since it assumes the data
	# track always occurs at the end, which in some game CD's it doesn't) and pass it to the command
	# line. Yes, it really is one line.
	
	local VALIDTRACKS="$(cdparanoia -d $CDROM -Q 2>&1 | egrep '^[[:space:]]+[[:digit:]]' | awk '{print $1}' | tr -d "." | tr '\n' ' ')"
	
	# Do it. Do it.	
		
	logger -p $LOGDEST.info "Info ($PROCESS): Starting encoding."
	
	abcde -Nx -d $CDROM $VALIDTRACKS > /dev/null 2>&1
		

	# If the disc is unknwon, give a warning and unique folder name.
	
	if [ -d "$PROCDIR/Unknown Artist - Unknown Album/" ]
	then
		logger -p $LOGDEST.warn "Warning ($PROCESS): Processed successfully, but info unknown."
		mv "$PROCDIR/Unknown Artist - Unknown Album" "$PROCDIR/Unkown Disc - ID $PROCESS"
	
	fi
	
	# If more than one folder is left, or the abcde.process folder is left over,
	# or if there's nothing in the directory, something has gone WRONG.
	
	if [ $(ls -1 "$PROCDIR" | wc -l) -gt 1 ] || [ "$(ls -1 "$PROCDIR")" = "abcde.$PROCESS" ] || [ "$(ls -1 "$PROCDIR")" = "" ]
	then
		logger -p $LOGDEST.error "Error ($PROCESS): More than one folder or something very bad happened."
		rm -r "$PROCDIR"
		return 0
	fi
		
	# Note: Don't declare discname until process is finished. Now is fine.
	
	local DISCNAME=`ls -1 "$PROCDIR"`
	
	# Put the current disc's ID into a file in the disc's folder, JIC
	
	echo "$THISDISC" > "$PROCDIR/$DISCNAME/disc_id"
	
	
	logger -p $LOGDEST.info "Info ($PROCESS): Encoding of "$DISCNAME" completed successfully."
	
	
	# Wait for the done database to be ready...

	until ! [ -f "$BASE/lib/done.lock" ] || [ $DONELOCK -ge 60 ]
	do
	sleep 10
	DONELOCK=$(($DONELOCK+10)) 
	done

	# Then add this disc to it.	
	if [ "`grep "$CURCD" $BASE/lib/done.db`" = "" ] 
 	then	
		touch "$BASE/lib/done.lock"
		cat "$BASE/lib/done.db" "$PROCDIR/$DISCNAME/disc_id" > "$BASE/lib/done.new"
		mv "$BASE/lib/done.new" "$BASE/lib/done.db"
		rm "$BASE/lib/done.lock"
	else
		logger -p $LOGDEST.notice "Not adding $PROCESS to done.db" 
	fi
	
	# Move the process's completed directory into the done folder.
	
	if ! [ -d "$DONE/$DISCNAME" ]
	then
		mv -f "$PROCDIR/$DISCNAME" "$DONE/"
	elif [ -d "$DONE/$DISCNAME" ]
	then
		rm -r "$DONE/$DISCNAME"
		mv -f "$PROCDIR/$DISCNAME" "$DONE/"
	fi
	
	# A file must be used here because the variable is lost when the function exits sometimes.	

	echo "$THISDISC" > "$BASE/lib/LASTDONE"
	
	# If I was the last disc started, and I'm done, clear the laststart variable so the last disc
	# encoded can be re-encoded if they really want to.
	
	if [ "$THISDISC" = "$LASTSTART" ]
	then
		LASTSTART=""
	fi

	
	# Remove the process temp directory and call it a day.
	
	rm -r "$PROCDIR"
	
}

until [[ $(< "$BASE/lib/stop") == 1 ]]
do
	main
done
