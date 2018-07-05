#!/usr/bin/env bash

# loading external configuration
source ./lib/config.shlib;

RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
RSYNC_SSH_OPTIONS="ssh -i $(config_get SSH_PRIV_KEY) -o StrictHostKeyChecking=no -l $(config_get SSH_USER)"
RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

RSYNC_SRC_JIRA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_FOLDER)"
RSYNC_DST_JIRA_FOLDER="$(config_get RSYNC_DST_JIRA_FOLDER)"

RSYNC_SRC_JIRA_DATA_FOLDER="$(config_get SSH_USER)@$(config_get SSH_SRC_HOST):$(config_get RSYNC_SRC_JIRA_DATA_FOLDER)"
RSYNC_DST_JIRA_DATA_FOLDER="$(config_get RSYNC_DST_JIRA_DATA_FOLDER)"

# First we need to stop local services
/etc/init.d/jira stop
if [ $? -ne 0 ]; then
	read -p "JIRA did not shutdown properly, exiting? (Y/N)" yn
	case ${yn} in
		[Yy]* ) exit 1;;
		[Nn]* ) echo "Continuing....";;
	esac
fi
# Now we sync all data from production to local folders
echo "Synching JIRA Program files from Production to Local Folder"

# Making sure the destination folders exists
mkdir -p ${RSYNC_DST_JIRA_FOLDER}
mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}

# Launching the rsync process

if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
   rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
else
    if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
    else
        rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_FOLDER} ${RSYNC_DST_JIRA_FOLDER}
    fi
fi

#Recreate the excluded folders
mkdir -p ${RSYNC_DST_JIRA_FOLDER}/logs
mkdir -p ${RSYNC_DST_JIRA_FOLDER}/temp

echo "Synching JIRA Data files from Production to Local Folder"
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
    rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="jira/tmp" --exclude="jira/log"  ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
else
    if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="jira/tmp" --exclude="jira/log" -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
    else
        rsync ${RSYNC_OPTIONS} --exclude="caches" --exclude="jira/tmp" --exclude="jira/log" -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_JIRA_DATA_FOLDER} ${RSYNC_DST_JIRA_DATA_FOLDER}
    fi
fi

#Recreate the excluded folders
mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/caches
mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/jira/tmp
mkdir -p ${RSYNC_DST_JIRA_DATA_FOLDER}/jira/log

# Now we need to cleanup the Configuration files
# jira-application.properties
JIRA_NEW_HOME="jira\.home = ${RSYNC_DST_JIRA_DATA_FOLDER}"

# We need to use # instead of / in the sed expression to be able to support the / in the path
# https://www.unix.com/shell-programming-and-scripting/148161-expand-environment-variable-sed-when-variable-contains-slash.html
sed -i 's#^[^#]*jira\.home.*#${JIRA_NEW_HOME}#g' ${RSYNC_DST_JIRA_DATA_FOLDER}/atlassian-jira/WEB-INF/classes/jira-application.properties

# We trigger a backup of the data on MySQL Server

# We must cleanup the backup before restoring the data

# We now need to restore the Data in the UAT DB

# Finally we start the services
