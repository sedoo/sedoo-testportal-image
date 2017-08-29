FROM php:5.4-apache

COPY config/php.ini /usr/local/etc/php/
COPY src/ /var/www/html/

RUN apt-get update && apt-get install -y \
	apt-utils \
	libpq-dev \
	libldap2-dev \
	git \
	unzip \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng12-dev \
	openjdk-7-jre \
	postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/php
COPY dependencies/fpdf17.zip fpdf17.zip 
RUN unzip -q fpdf17.zip \
 &&  ln -s fpdf17 fpdf \
 && rm fpdf17.zip

COPY dependencies/jpgraph.zip jpgraph.zip
RUN unzip -q jpgraph.zip \
 && ln -s jpgraph-3.5.0b1/src jpgraph \
 && rm jpgraph.zip

RUN curl -sLo sedoo-metadata.zip https://github.com/sedoo/sedoo-metadata-php/archive/1.0.2.zip \
 && unzip -jqd sedoo-metadata/ sedoo-metadata.zip \
 && rm sedoo-metadata.zip
				
RUN docker-php-ext-install pgsql

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu
RUN docker-php-ext-install ldap

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

RUN a2enmod socache_shmcb
RUN a2enmod ssl
RUN a2enmod cgi

RUN pear install HTML_QuickForm
RUN pear install "channel://pear.php.net/OLE-1.0.0RC3"
RUN pear install "channel://pear.php.net/Spreadsheet_Excel_Writer-0.9.4"

WORKDIR /usr/share/php/elastic
COPY config/elastic_composer.json composer.json
RUN curl -s http://getcomposer.org/installer | php
RUN php composer.phar install --no-dev

RUN openssl req -x509 -nodes -days 365 -newkey rsa:1024 \
 -out /etc/apache2/server.crt -keyout /etc/apache2/server.key \
 -subj "/C=FR/ST=Toulouse/L=Toulouse/O=OMP/OU=SEDOO/CN=sedoo.fr"

COPY config/apache2/000-default.conf /etc/apache2/sites-enabled/
COPY config/apache2/ssl.conf /etc/apache2/sites-enabled/

WORKDIR /sites