#!/bin/bash
# SPDX-License-Identifier: copyleft-next-0.3.1

source ${TOPDIR}/.config
source ${TOPDIR}/scripts/lib.sh

COUNT=1

run_loop()
{
	while true; do
		echo "== kernel-ci blktests test loop $COUNT start: $(date)" > $KERNEL_CI_FAIL_LOG
		echo "/usr/bin/time -f %E make blktests-baseline" >> $KERNEL_CI_FAIL_LOG
		/usr/bin/time -p -o $KERNEL_CI_LOGTIME make blktests-baseline >> $KERNEL_CI_FAIL_LOG
		echo "End   $COUNT: $(date)" >> $KERNEL_CI_FAIL_LOG
		cat $KERNEL_CI_LOGTIME >> $KERNEL_CI_FAIL_LOG
		echo "git status:" >> $KERNEL_CI_FAIL_LOG
		git status >> $KERNEL_CI_FAIL_LOG
		echo "Results:" >> $KERNEL_CI_FAIL_LOG

		rm -f $KERNEL_CI_DIFF_LOG

		DIFF_COUNT=$(git diff workflows/blktests/expunges/ | wc -l)
		if [[ "$DIFF_COUNT" -ne 0 ]]; then
			echo "Detected a failure as reported by differences in our expunge list" >> $KERNEL_CI_DIFF_LOG
		fi

		NEW_EXPUNGE_FILES="no"
		${TOPDIR}/playbooks/python/workflows/blktests/get_new_expunge_files.py workflows/blktests/expunges/ > .tmp.new_expunges
		NEW_EXPUNGE_FILE_COUNT=$(cat .tmp.new_expunges | wc -l | awk '{print $1}')
		if [[ $NEW_EXPUNGE_FILE_COUNT -ne 0 ]]; then
			NEW_EXPUNGE_FILES="yes"
			echo "Detected a failure since new expunge files were found which are not commited into git" >> $KERNEL_CI_DIFF_LOG
			echo "New expunge file found, listing output below:" >> $KERNEL_CI_DIFF_LOG
			cat .tmp.new_expunges >> $KERNEL_CI_DIFF_LOG
			rm -f .tmp.new_expunges
		fi
		rm -f .tmp.new_expunges

		if [[ "$DIFF_COUNT" -ne 0 || "$NEW_EXPUNGE_FILES" == "yes" ]]; then
			echo "Test  $COUNT: FAILED!" >> $KERNEL_CI_DIFF_LOG
			echo "== Test loop count $COUNT" >> $KERNEL_CI_DIFF_LOG
			echo "$(git describe)" >> $KERNEL_CI_DIFF_LOG
			git diff workflows/blktests/expunges/ >> $KERNEL_CI_DIFF_LOG
			cat $KERNEL_CI_DIFF_LOG >> $KERNEL_CI_FAIL_LOG
			cat $KERNEL_CI_FAIL_LOG >> $KERNEL_CI_FULL_LOG
			echo $COUNT > $KERNEL_CI_FAIL_FILE
			exit 1
		else
			echo "Test  $COUNT: OK!" >> $KERNEL_CI_FAIL_LOG
			echo "----------------------------------------------------------------" >> $KERNEL_CI_FAIL_LOG
			cat $KERNEL_CI_FAIL_LOG >> $KERNEL_CI_FULL_LOG
		fi
		echo $COUNT > $KERNEL_CI_OK_FILE
		let COUNT=$COUNT+1
		if [[ "$CONFIG_KERNEL_CI_ENABLE_STEADY_STATE" == "y" &&
		      "$COUNT" -gt "$CONFIG_KERNEL_CI_STEADY_STATE_GOAL" ]]; then
			exit 0
		fi
		sleep 1
	done
}

rm -f $KERNEL_CI_FAIL_FILE $KERNEL_CI_OK_FILE
echo "= kernel-ci full log" > $KERNEL_CI_FULL_LOG
run_loop
