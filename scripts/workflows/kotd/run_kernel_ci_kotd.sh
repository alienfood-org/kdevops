#!/bin/bash
# SPDX-License-Identifier: copyleft-next-0.3.1

# Part of kdevops kernel-ci, this script is in charge of updating your
# kernel after each kernel-ci loop.

if [[ "$TOPDIR" == "" ]]; then
	TOPDIR=$PWD
fi

TARGET_WORKFLOW="$(basename $(dirname $0))"

if [[ ! -f ${TOPDIR}/.config || ! -f ${TOPDIR}/scripts/lib.sh ]]; then
	echo "Unconfigured system"
	exit 1
fi

source ${TOPDIR}/.config
source ${TOPDIR}/scripts/lib.sh

rm -f ${TOPDIR}/.kotd.*

if [[ "$CONFIG_KERNEL_CI" != "y" ]]; then
	echo "Must enable CONFIG_KERNEL_CI to use this feature"
	exit 1
fi

TARGET_HOSTS="baseline"
if [[ "$1" != "" ]]; then
	TARGET_HOSTS=$1
fi

kotd_log()
{
	NOW=$(date --rfc-3339='seconds' | awk -F"+" '{print $1}')
	echo "$NOW : $@" >> $KOTD_LOG
}

KOTD_LOOP_COUNT=1

kotd_log "Begin KOTD work"

kotd_rev_kernel()
{
	kotd_log "***********************************************************"
	kotd_log "Begin KOTD loop #$KOTD_LOOP_COUNT"
	kotd_log "---------------------------------"

	if [[ "$CONFIG_WORKFLOW_KOTD_ENABLE" != "y" ]]; then
		return
	fi

	kotd_log "Going to try to rev kernel"
	/usr/bin/time -f %E -o $KOTD_LOGTIME make kotd-${TARGET_HOSTS}
	if [[ $? -ne 0 ]]; then
		kotd_log "failed running: make kotd-$TARGET_HOSTS"
		if [[ -f $KOTD_BEFORE ]]; then
			KERNEL_BEFORE="$(cat $KOTD_BEFORE)"
			kotd_log "KOTD before: $KERNEL_BEFORE"
		fi
		if [[ -f $KOTD_AFTER ]]; then
			KERNEL_AFTER="$(cat $KOTD_BEFORE)"
			kotd_log "KOTD after: $KERNEL_AFTER"
		fi
		THIS_KOTD_LOGTIME=$(cat $KOTD_LOGTIME)
		kotd_log "KOTD reving work failed after this amount of time: $THIS_KOTD_LOGTIME"
		exit 1
	fi

	THIS_KOTD_LOGTIME=$(cat $KOTD_LOGTIME)
	kotd_log "KOTD reving work succeeded after this amount of time: $THIS_KOTD_LOGTIME"

	KERNEL_BEFORE=""
	if [[ -f $KOTD_BEFORE ]]; then
		KERNEL_BEFORE="$(cat $KOTD_BEFORE)"
		kotd_log "KOTD before: $KERNEL_BEFORE"
	fi
	KERNEL_AFTER=""
	if [[ -f $KOTD_AFTER ]]; then
		KERNEL_AFTER="$(cat $KOTD_BEFORE)"
		kotd_log "KOTD after:  $KERNEL_AFTER"
		if [[ "$KERNEL_BEFORE" == "$KERNEL_AFTER" ]]; then
			kotd_log "KOTD no updates were made, kernel remains identical"
		else
			kotd_log "KOTD kernel was updated"
		fi
	fi
}

while true; do
	kotd_rev_kernel
	if [[ "$CONFIG_KERNEL_CI_ENABLE_STEADY_STATE" == "y" ]]; then
		kotd_log "Running the $TARGET_WORKFLOW kernel-ci loop with a steady state goal of $CONFIG_KERNEL_CI_STEADY_STATE_GOAL"
	else
		kotd_log "Running the $TARGET_WORKFLOW kernel-ci loop with no steady state goal set"
	fi
	/usr/bin/time -f %E -o $KOTD_LOGTIME make $TARGET_WORKFLOW-${TARGET_HOSTS}-loop
	if [[ $? -ne 0 ]]; then
		kotd_log "failed running: make $TARGET_WORKFLOW-${TARGET_HOSTS}-loop"
		THIS_KOTD_LOGTIME=$(cat $KOTD_LOGTIME)
		kotd_log "$TARGET_WORKFLOW kernel-ci work failed after this amount of time: $THIS_KOTD_LOGTIME"
		exit 1
	fi
	THIS_KOTD_LOGTIME=$(cat $KOTD_LOGTIME)
	kotd_log "Completed kernel-ci loop work for $TARGET_WORKFLOW successfully after this amount of time: $THIS_KOTD_LOGTIME"
	let KOTD_LOOP_COUNT=$KOTD_LOOP_COUNT+1
done
