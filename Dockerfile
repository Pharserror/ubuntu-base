FROM ubuntu:trusty
MAINTAINER Pharserror <sunboxnet@gmail.com>
ENV REFRESHED_AT 2015-09-03

# Setup environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV RUBY_VERSION 2.2.0
ENV APACHE_RUN_USER=worker
ENV APACHE_RUN_GROUP=worker
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/var/log/apache2
ENV BITBUCKET_USER=buttfart
ENV BITBUCKET_PASS=password
ENV BITBUCKET_PROJECT=dockerinit
ENV APACHE_RAILS_ENV=development
ENV SERVER_ADMIN_EMAIL=webmaster@localhost

USER root

# Setup User
RUN useradd --home /home/worker -M worker -K UID_MIN=10000 -K GID_MIN=10000 -s /bin/bash
RUN mkdir /home/worker
RUN chown worker:worker /home/worker
RUN adduser worker sudo
RUN echo 'worker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER worker

# Update 
RUN sudo apt-get update
RUN sudo apt-get install -y curl gnupg build-essential libssl-dev libyaml-dev libreadline-dev openssl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev apt-transport-https ca-certificates openssh-client

# install RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -sSL https://get.rvm.io | sudo bash -s stable
RUN sudo usermod -a -G rvm `whoami`

# set secure path if needed
RUN if sudo grep -q secure_path /etc/sudoers; then sudo sh -c "echo export rvmsudo_secure_path=1 >> /etc/profile.d/rvm_secure_path.sh" && echo Environment variable installed; fi

# install ruby
RUN /bin/bash -l -c 'rvm install ruby-$RUBY_VERSION'
RUN /bin/bash -l -c 'rvm --default use ruby-$RUBY_VERSION'

# install bundler
RUN /bin/bash -l -c 'gem install bundler --no-rdoc --no-ri'

# install node
RUN sudo apt-get install -y npm nodejs nodejs-legacy --no-install-recommends && sudo ln -sf /usr/bin/nodejs /usr/local/bin/node

# Apache
RUN sudo apt-get -y install apache2 

RUN sudo service apache2 restart

# Install our PGP key and add HTTPS support for APT
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7

USER root

RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" >> /etc/apt/sources.list.d/passenger.list

USER worker

RUN sudo chown root: /etc/apt/sources.list.d/passenger.list
RUN sudo chmod 600 /etc/apt/sources.list.d/passenger.list

RUN sudo apt-get update

# Install Passenger + Apache module
RUN sudo apt-get install -y libapache2-mod-passenger

# add site and apache configurations

# enable apache module and restart
RUN sudo a2enmod passenger
RUN sudo apache2ctl restart

# check install
RUN sudo passenger-config validate-install
RUN sudo passenger-memory-stats

# update
RUN sudo apt-get update

# now we add the script and make it executable
COPY ./init.sh /
COPY ./railsapp.apacheconf /
RUN sudo chown worker:worker /init.sh
RUN sudo chown worker:worker /railsapp.apacheconf
RUN sudo chmod +x /init.sh
ENTRYPOINT ["/init.sh"]

EXPOSE 80
