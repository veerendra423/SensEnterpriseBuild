#!/bin/bash

export SCONE_CLI_CONFIG="~/.cas/dataowner-config.json"

/opt/scone/bin/rust-cli self show-certificate-hash
