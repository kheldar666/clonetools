#!/usr/bin/env bash
source ../src/lib/config.shlib; # load the config library functions
echo "$(config_get RSYNC_OPTIONS)"; # will be found in user-cfg
printf -- "%s\n" "$(config_get RSYNC_SSH_OPTIONS)"; # safer way of echoing!
echo "$(config_get RSYNC_DST_JIRA_FOLDER)"; # will fall back to defaults
echo "$(config_get bleh)"; # "__UNDEFINED__" since it isn't set anywhere