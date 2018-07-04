#!/usr/bin/env bash

RSYNC_OPTIONS=-rav --delete
RSYNC_SSH_OPTIONS=""

RSYNC_SRC_JIRA_FOLDER=someuser@somehost:/path/to/jira
RSYNC_DST_JIRA_FOLDER=/path/to/local/folder/jira

# Tetsing RSYNC
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
    rsync ${RSYNC_OPTIONS} ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
else
    rsync ${RSYNC_OPTIONS} -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
fi