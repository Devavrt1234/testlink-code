FROM php:7.4-apache

# Declare build arguments
#ARG POSTGRES_HOST
#ARG POSTGRES_DB
#ARG POSTGRES_USER
#ARG POSTGRES_PASSWORD

# Update and install dependencies
RUN apt update && apt upgrade -y

# Install required packages for PHP extensions and PostgreSQL
RUN apt install -y \
  default-mysql-client \
  zlib1g-dev \
  libpng-dev \
  libjpeg-dev \
  libfreetype-dev \
  postgresql-client \
  libpq-dev \
  postgresql-common

# Install PDO and PostgreSQL extensions for PHP
RUN docker-php-ext-install pdo pdo_pgsql pgsql

# Install and enable mysqli and GD extensions
RUN docker-php-ext-install mysqli && \
  docker-php-ext-enable mysqli && \
  docker-php-ext-configure gd --with-freetype --with-jpeg && \
  docker-php-ext-install gd

# Clean up
RUN apt clean

# Set up TestLink directory
RUN mkdir -p /var/www/testlink

WORKDIR /var/www/testlink

# Copy files into the container
COPY . .
COPY ./docker/php.ini-production /usr/local/etc/php/conf.d/php.ini

# Set ownership and remove docker folder
RUN chown -R www-data:www-data /var/www/testlink
RUN rm -rf docker

# Set Apache document root
ENV APACHE_DOCUMENT_ROOT /var/www/testlink
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Create necessary directories with proper permissions
RUN mkdir -p /var/testlink/logs /var/testlink/upload_area && \
  chown -R www-data:www-data /var/testlink/logs /var/testlink/upload_area && \
  chmod -R 755 /var/testlink/logs /var/testlink/upload_area

# Modify TestLink config file with PostgreSQL details
#RUN sed -i "s|\$tlCfg->dbhost = 'localhost';|\$tlCfg->dbhost = '${POSTGRES_HOST}';|g" /var/www/testlink/config.inc.php
#RUN sed -i "s|\$tlCfg->dbname = 'testlink';|\$tlCfg->dbname = '${POSTGRES_DB}';|g" /var/www/testlink/config.inc.php
#RUN sed -i "s|\$tlCfg->dbuser = 'root';|\$tlCfg->dbuser = '${POSTGRES_USER}';|g" /var/www/testlink/config.inc.php
#RUN sed -i "s|\$tlCfg->dbpass = 'root';|\$tlCfg->dbpass = '${POSTGRES_PASSWORD}';|g" /var/www/testlink/config.inc.php

# Switch to www-data user
USER www-data

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]
