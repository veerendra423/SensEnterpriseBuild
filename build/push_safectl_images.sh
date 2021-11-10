#! /bin/bash
if [ $# -ne 1 ]; then
  echo "usage: push_safectl_images.sh releaseVersion"
  echo "example: push_safectl_images.sh VERSION_1_3_3-devel"
  exit 1
fi

source /mnt/staging/default-creds.env

from=$SENSCR_NAME
to=$SENS_SAFECTL_EXTERNAL_REG
releaseVersion=$1
echo $SENSCR_PASSWD | docker login $from --username $SENSCR_USER --password-stdin
echo $SENS_SAFECTL_EXTERNAL_REG_PASSWD | docker login $to --username $SENS_SAFECTL_EXTERNAL_REG_USER --password-stdin


echo "Copying images used by Safectl from Internal image registry to external registry"
for item in "$SENSCR_IMGREPO_NAME/python-3.8.1-ubuntu:11302020" "$SENSCR_IMGREPO_NAME/sensencrypt:$releaseVersion" "$SENSCR_IMGREPO_NAME/sensdecrypt:$releaseVersion" "$SENSCR_IMGREPO_NAME/sensgcspush:$releaseVersion" "$SENSCR_IMGREPO_NAME/sensgcspull:$releaseVersion" "$SENSCR_IMGREPO_NAME/scli:$releaseVersion" "$SENSCR_IMGREPO_NAME/sensrefimage:11302020" "$SENSCR_IMGREPO_NAME/python-3.8.1:20210928-small"
do
  fullFrom=$from/$item
  fullTo=$to/${item/$SENSCR_IMGREPO_NAME/safelishare}
  echo "copying from $fullFrom to $fullTo"
  docker pull $fullFrom
  docker tag $fullFrom $fullTo
  docker push $fullTo
done
echo Done

