#!/usr/bin/env bash

RSYNC_OPTIONS=-rav --delete
RSYNC_SSH_OPTIONS=

RSYNC_SRC_JIRA_FOLDER=someuser@somehost:/path/to/jira
RSYNC_DST_JIRA_FOLDER=/path/to/local/folder/jira

# Now we sync all data from production to local folders
echo "Synching JIRA Program files from Production to Local Folder"
rsync $RSYNC_OPTIONS $RSYNC_SSH_OPTIONS $RSYNC_SRC_JIRA_FOLDER $RSYNC_DST_JIRA_FOLDER