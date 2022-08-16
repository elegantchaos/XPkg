# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 swift:5.6-bionic
RUN apt-get -y update
RUN apt-get install curl
COPY test.sh .
