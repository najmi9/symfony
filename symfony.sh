#!/bin/bash

database_name=dev
github_token=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
repo_name=digital-wallekers

# Generate a random password
sql_password=$(openssl rand -base64 16)

# Update repositories
sudo apt-get update

# Install essential tools
sudo apt-get install -y curl git vim make software-properties-common

# Install PHP and common extensions
sudo apt-get -y install php8.2-cli
sudo apt-get install -y php8.2-{mysql,xml,bcmath,bz2,intl,mbstring,mysql,zip,common,curl,gmp,fpm}

# Install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --filename=composer --install-dir=/usr/local/bin
php -r "unlink('composer-setup.php');"

# Setup mysql database
sudo apt-get update
sudo apt-get -y install mysql-server

echo "CREATE USER 'user'@'localhost' IDENTIFIED BY '$sql_password'" | sudo mysql -u root;
echo "CREATE DATABASE $database_name" | sudo mysql -u root;
echo "GRANT ALL PRIVILEGES ON $database_name.* TO 'user'@'localhost'" | sudo mysql -u root;
echo "FLUSH PRIVILEGES" | sudo mysql -u root;

# Donwload github code
cd /usr/share/nginx/html
git clone https://$github_token@github.com/najmi9/$repo_name symfony
cd symfony
echo "DATABASE_URL=mysql://user:$sql_password@localhost:3306/$database_name" > .env.local

# Install symfony dependencies
composer install --no-interaction
# Make migration
php bin/console doctrine:schema:update --force

# Install nginx
sudo service apache2 stop
sudo service apache2 disable
sudo apt-get purge -y apache2

sudo apt-get install -y nginx
# copy the configuration
cp ~/nginx.conf /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/
sudo service nginx restart

echo "Done!!";
