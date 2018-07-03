#!/usr/bin/env bash

# loading external configuration
source config.shlib;

RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
RSYNC_SSH_OPTIONS="$(config_get RSYNC_SSH_OPTIONS)"

RSYNC_SRC_JIRA_FOLDER="$(config_get RSYNC_SRC_JIRA_FOLDER)"
RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

RSYNC_SRC_CONF_FOLDER="$(config_get RSYNC_SRC_CONF_FOLDER)"
RSYNC_DST_CONF_FOLDER="$(config_get RSYNC_DST_CONF_FOLDER)"

RSYNC_SRC_CONF_DATA_FOLDER="$(config_get RSYNC_SRC_CONF_DATA_FOLDER)"
RSYNC_DST_CONF_DATA_FOLDER="$(config_get RSYNC_DST_CONF_DATA_FOLDER)"

# First we need to stop both local services
/etc/init.d/jira stop
if [$1 == 1]; then
	read -p "JIRA did not shutdown properly, exiting? (Y/N)" yn
	case $yn in
		[Yy]* ) exit 1;;
		[Nn]* ) echo "Continuing....";
	esac
fi

/etc/init.d/confluence stop
if [$1 == 1]; then
        read -p "Confluence did not shutdown properly, exiting? (Y/N)" yn
        case $yn in
                [Yy]* ) exit 1;;
                [Nn]* ) echo "Continuing....";
        esac
fi

# Now we sync all data from production to local folders

# First we take care of JIRA
echo "Synching JIRA Program files from Production to Local Folder"
rsync $RSYNC_OPTIONS $RSYNC_SSH_OPTIONS $RSYNC_SRC_JIRA_FOLDER $RSYNC_DST_JIRA_FOLDER

echo "Synching JIRA Data files from Production to Local Folder"
rsync $RSYNC_OPTIONS $RSYNC_SSH_OPTIONS $RSYNC_SRC_JIRA_DATA_FOLDER $RSYNC_DST_JIRA_DATA_FOLDER

# Then we take care of Confluence
echo "Synching Confluence Program files from Production to Local Folder"
rsync $RSYNC_OPTIONS $RSYNC_SSH_OPTIONS $RSYNC_SRC_CONF_FOLDER $RSYNC_DST_CONF_FOLDER

echo "Synching Confluence Data files from Production to Local Folder"
rsync $RSYNC_OPTIONS $RSYNC_SSH_OPTIONS $RSYNC_SRC_CONF_DATA_FOLDER $RSYNC_DST_CONF_DATA_FOLDER

# Now we need to cleanup the Configuration files

# We trigger a backup of the data on MySQL Server

# We must cleanup the backup before restoring the data

# We now need to restore the Data in the UAT DB

# Finally we start the services
