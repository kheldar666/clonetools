# JIRA and Confluence cloning tools

This is a set of scripts allowing to Clone completely an instance of JIRA or Confluence from Server A to B in one script
 execution. The main purpose is to be able to clone a Production
 environment back to a Test environment for testing purposes (ie:
 testing an Upgrade or new plugins).

Fell free to contribute to improve this tool.

## Notes

To clone a standard installation of JIRA/Confluence (installed as 'root') you will probably need the following
(assuming that you cannot connect to the remote server as root, which I hope you can't):

* Set RSYNC_SSH_OPTIONS properly (something like `RSYNC_SSH_OPTIONS=ssh -i /path/to/key -l username`)
* the username in the option above must match the RSYNC_SRC_JIRA_FOLDER username@server:/path )
* Make sure the user that will connect through ssh can sudo the rsync command
* Set the RSYNC_REMOTE_SUDO options properly ( something like : `RSYNC_REMOTE_SUDO=sudo rsync`)

## Instructions

1. To create your own configuration, please create the file `config.cfg` next to `config.cfg.defaults` in the `resources` folder
2. Run the program : `sh clone-jira.sh` or `sh clone-confluence.sh`, eventually use the `-r` option to resume from a specific step


## Configuration Options

Please check `resources/config.cfg.default` file for details
