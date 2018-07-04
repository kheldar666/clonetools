#!/usr/bin/env bash

# loading external configuration
source ./lib/config.shlib;

RSYNC_OPTIONS="$(config_get RSYNC_OPTIONS)"
RSYNC_SSH_OPTIONS="$(config_get RSYNC_SSH_OPTIONS)"
RSYNC_REMOTE_SUDO="$(config_get RSYNC_REMOTE_SUDO)"

RSYNC_SRC_CONF_FOLDER="$(config_get RSYNC_SRC_CONF_FOLDER)"
RSYNC_DST_CONF_FOLDER="$(config_get RSYNC_DST_CONF_FOLDER)"

RSYNC_SRC_CONF_DATA_FOLDER="$(config_get RSYNC_SRC_CONF_DATA_FOLDER)"
RSYNC_DST_CONF_DATA_FOLDER="$(config_get RSYNC_DST_CONF_DATA_FOLDER)"

/etc/init.d/confluence stop
if [ $? -ne 1 ]; then
        read -p "Confluence did not shutdown properly, exiting? (Y/N)" yn
        case $yn in
                [Yy]* ) exit 1;;
                [Nn]* ) echo "Continuing....";
        esac
fi

# Now we sync all data from production to local folders
echo "Synching Confluence Program files from Production to Local Folder"
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
    rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" ${RSYNC_SRC_CONF_FOLDER} ${RSYNC_DST_CONF_FOLDER}
else
    if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_CONF_FOLDER} ${RSYNC_DST_CONF_FOLDER}
    else
        rsync ${RSYNC_OPTIONS} --exclude="logs" --exclude="temp" -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_CONF_FOLDER} ${RSYNC_DST_CONF_FOLDER}
    fi
fi

#Recreate the excluded folders
mkdir -p ${RSYNC_DST_CONF_FOLDER}/logs
mkdir -p ${RSYNC_DST_CONF_FOLDER}/temp

echo "Synching Confluence Data files from Production to Local Folder"
if [ ${#RSYNC_SSH_OPTIONS} -eq 0 ] ; then
    rsync ${RSYNC_OPTIONS} ${RSYNC_SRC_CONF_DATA_FOLDER} ${RSYNC_DST_CONF_DATA_FOLDER}
else
    if [ ${#RSYNC_REMOTE_SUDO} -eq 0 ] ; then
        rsync ${RSYNC_OPTIONS} -e "${RSYNC_SSH_OPTIONS}" ${RSYNC_SRC_CONF_DATA_FOLDER} ${RSYNC_DST_CONF_DATA_FOLDER}
    else
        rsync ${RSYNC_OPTIONS} -e "${RSYNC_SSH_OPTIONS}" --rsync-path="${RSYNC_REMOTE_SUDO}" ${RSYNC_SRC_CONF_DATA_FOLDER} ${RSYNC_DST_CONF_DATA_FOLDER}
    fi
fi

# Now we need to cleanup the Configuration files

# We trigger a backup of the data on MySQL Server

# We must cleanup the backup before restoring the data

# We now need to restore the Data in the UAT DB

# Finally we start the services
