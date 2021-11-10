FROM sensoriant.azurecr.io/priv-comp/sconecli:latest

RUN apk add python3 && apk add curl && apk add openssl

RUN apk add --update py-pip

RUN apk add jq

RUN apk add make

RUN apk add gcc && apk add python3-dev && apk add musl-dev && apk add linux-headers

RUN apk add tzdata

RUN pip3 install --upgrade pip

RUN pip3 install yq

RUN python3 -m pip install pexpect

RUN python3 -m pip install prefect

RUN mkdir /input

RUN apk add --no-cache libc6-compat

ADD start /start

ADD encrypt /encrypt

ADD senspush.py /senspush.py

WORKDIR /
