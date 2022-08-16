# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 swift:5.6-bionic
RUN apt-get -y update
RUN apt-get install curl
RUN useradd -ms /bin/bash tester
USER tester
WORKDIR /home/tester
COPY test.sh .
