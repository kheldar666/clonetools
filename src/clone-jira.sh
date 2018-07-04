#!/usr/bin/env bash

# loading external configuration
source ./lib/config.shlib;

RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
RSYNC_SSH_OPTIONS="$(config_get RSYNC_SSH_OPTIONS)"

RSYNC_SRC_JIRA_FOLDER="$(config_get RSYNC_SRC_JIRA_FOLDER)"
RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

# First we need to stop local services
/etc/init.d/jira stop
if [ $? -ne 0 ]; then
	read -p "JIRA did not shutdown properly, exiting? (Y/N)" yn
	case $yn in
		[Yy]* ) exit 1;;
		[Nn]* ) echo "Continuing....";
	esac
fi
# Now we sync all data from production to local folders
echo "Synching JIRA Program files from Production to Local Folder"
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
   rsync ${RSYNC_OPTIONS} ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
else
   rsync ${RSYNC_OPTIONS} -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
fi

echo "Synching JIRA Data files from Production to Local Folder"
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
   rsync ${RSYNC_OPTIONS} ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
else
   rsync ${RSYNC_OPTIONS} -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
fi

# Now we need to cleanup the Configuration files

# We trigger a backup of the data on MySQL Server

# We must cleanup the backup before restoring the data

# We now need to restore the Data in the UAT DB

# Finally we start the services
