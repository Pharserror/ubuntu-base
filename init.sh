#!/bin/bash

# add files
sudo mkdir /var/www/$BITBUCKET_PROJECT

sudo chown worker:worker -R /var/www/
sudo chown worker:worker -R /var/www/$BITBUCKET_PROJECT

sudo chown worker:worker /etc/apache2/sites-enabled/000-default.conf
sudo chown worker:worker /etc/apache2/apache2.conf

sudo mv /railsapp.apacheconf /etc/apache2/sites-enabled/000-default.conf

# add env vars to apache2.conf
echo "Define SERVER_ADMIN_EMAIL $SERVER_ADMIN_EMAIL" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define BITBUCKET_PROJECT $BITBUCKET_PROJECT" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_RAILS_ENV $APACHE_RAILS_ENV" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_RUN_USER $APACHE_RUN_USER" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_RUN_GROUP $APACHE_RUN_GROUP" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_PID_FILE $APACHE_PID_FILE" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_RUN_DIR $APACHE_RUN_DIR" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_LOCK_DIR $APACHE_LOCK_DIR" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf
echo "Define APACHE_LOG_DIR $APACHE_LOG_DIR" | cat - /etc/apache2/apache2.conf > /home/worker/apache2.conf.tmp && sudo mv /home/worker/apache2.conf.tmp /etc/apache2/apache2.conf

sudo chown root:root /etc/apache2/sites-enabled/000-default.conf
sudo chown root:root /etc/apache2/apache2.conf

mkdir /home/worker/.ssh
cd /home/worker/.ssh
ssh-keygen -t rsa -f worker_rsa -N '' && cat ./worker_rsa.pub | while read key; do curl --user "$BITBUCKET_USER:$BITBUCKET_PASS" --data-urlencode "key=$key" -X POST https://bitbucket.org/api/1.0/users/$BITBUCKET_USER/ssh-keys ; done
touch known_hosts
ssh-keyscan bitbucket.org >> known_hosts

cd /var/www
git clone https://$BITBUCKET_USER:$BITBUCKET_PASS@bitbucket.org/$BITBUCKET_USER/$BITBUCKET_PROJECT.git
cd /var/www/$BITBUCKET_PROJECT

/bin/bash -l -c 'bundle install --deployment --without development test'
/bin/bash -l -c 'npm install'
/bin/bash -l -c 'npm install webpack -g'
/bin/bash -l -c 'webpack'
/bin/bash -l -c 'bundle exec rake assets:precompile db:migrate'

sudo apache2ctl restart && tail -f /dev/null
