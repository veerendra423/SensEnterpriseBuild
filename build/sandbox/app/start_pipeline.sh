#!/bin/bash
echo $1
SANDBOX_DIR=./operator/SensADK/sandbox
cp $HOME/$1 $SANDBOX_DIR/pipeline.json
rm -f $SANDBOX_DIR/config
./run.sh << EOL | tee >(logger -e -t "Sandbox")
9
6
EOL
rc=${PIPESTATUS[0]}
source .env
if [ ! "$SBOX_KEEP_KEYS" = "true" ]; then
   rm -f config.yml > /dev/null
   rm -f operator/SensADK/sandbox/image/sdata/default/.env > /dev/null
   rm -f operator/SensADK/sandbox/image/sdata/default/* > /dev/null
fi
exit $rc
