#!/bin/bash

# add files
sudo mkdir /var/www/$BITBUCKET_PROJECT

sudo chown worker:worker -R /var/www/
sudo chown worker:worker -R /var/www/$BITBUCKET_PROJECT

sudo chown worker:worker /etc/apache2/sites-enabled/000-default.conf
sudo chown worker:worker /etc/apache2/apache2.conf

sudo curl -L --user "$BITBUCKET_USER:$BITBUCKET_PASS" "$SITE_CONF_URL" > /etc/apache2/sites-enabled/000-default.conf
sudo curl -L --user "$BITBUCKET_USER:$BITBUCKET_PASS" "$APACHE2_CONF_URL" > /etc/apache2/apache2.conf

sudo chown root:root /etc/apache2/sites-enabled/000-default.conf
sudo chown root:root /etc/apache2/apache2.conf

mkdir /home/worker/.ssh
cd /home/worker/.ssh
ssh-keygen -t rsa -f worker_rsa -N '' && cat ./worker_rsa.pub | while read key; do curl --user "$BITBUCKET_USER:$BITBUCKET_PASS" --data-urlencode "key=$key" -X POST https://bitbucket.org/api/1.0/users/$BITBUCKET_USER/ssh-keys ; done

cd /var/www
/bin/bash -l -c 'git clone $REPO_URL'
cd /var/www/$BITBUCKET_PROJECT

/bin/bash -l -c 'bundle install --deployment --without development test'
/bin/bash -l -c 'npm install'
/bin/bash -l -c 'bundle exec rake assets:precompile db:migrate'

sudo apache2ctl restart && tail -f /dev/null
