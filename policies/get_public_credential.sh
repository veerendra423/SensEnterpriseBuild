#!/bin/bash

export SCONE_CLI_CONFIG="~/.cas/dataowner-config.json"

scone self show-key-hash
#/opt/scone/bin/rust-cli self show-certificate-hash
