#!/bin/bash

if [ -z "$1" ] ; then
    echo "Missing tagname"
    exit 1
fi
TAGNAME=$1
git tag $TAGNAME; git push origin --tags
git submodule foreach -q --recursive 'branch="$(git config -f ../../.gitmodules submodule.$sm_path.branch)"; git tag '"$TAGNAME"'; git push origin --tags'

