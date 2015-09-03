FROM ubuntu:trusty
MAINTAINER Pharserror <sunboxnet@gmail.com>
ENV REFRESHED_AT 2015-09-03

USER root

# Update 
RUN apt-get update
#RUN apt-get upgrade -y
RUN apt-get install curl -y --fix-missing

# Setup environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
