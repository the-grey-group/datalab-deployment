#!/bin/bash
# This script retrieves the password for the current git repository from a Bitwarden Vault.
# If bw is not available, it should error out
set -e
bw get password "grey-group-datalab"
