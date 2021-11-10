#FROM sensoriant.azurecr.io/priv-comp/sconecli:VERSION_0_0_2
#FROM sconecuratedimages/sconecli:alpine3.7-scone4.2.1
#FROM sensoriant.azurecr.io/sconecli4.2.1
FROM sensoriant.azurecr.io/priv-comp/sconecli:VERSION_5_2_0

RUN apk add python3 && apk add curl

RUN apk add --update py-pip

RUN apk add jq

RUN pip install yq

COPY . /policies

COPY helper_scripts /helper_scripts
