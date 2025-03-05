#! /bin/bash

sudo docker run --rm --name dvna-mysql --env-file vars.env -d mysql:5.7
sudo docker run --rm --name dvna-app --env-file vars.env --link dvna-mysql:mysql-db -p 9090:9090 appsecco/dvna
#npm install
#nodemon
