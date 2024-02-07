FROM mariadb:10.6

#mariadb

#end mariadb
#wordpress
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mariadb-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 curl \
                 php-zip \
                 phpmyadmin -yq \
                 && apt-get clean \
                 && rm -rf /var/lib/apt/lists/*

RUN { \
        echo phpmyadmin phpmyadmin/mysql/admin-user string root; \
        echo phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD; \
        echo phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASSWORD; \
        echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2; \
    } | debconf-set-selections \
    && dpkg-reconfigure -f noninteractive phpmyadmin \
    && echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf \
    && { \
            mkdir -p /srv/backup; \
            curl https://wordpress.org/latest.tar.gz | tar zx -C /srv/backup; \
            mkdir -p /srv/www/wordpress; \
            cp -rf /etc/apache2 /srv/backup; \
        }
WORKDIR /srv/www/wordpress
RUN echo '#!/bin/bash \n\
    set -eo pipefail \n\
    shopt -s nullglob \n\ 
    if [ ! -f "/srv/backup/apache2/sites-available/wordpress.conf" ]; then \n\
        mkdir -p /srv/backup/apache2/sites-available \n\
        echo "<VirtualHost *:80> \n\         
            RewriteEngine On \n\
            #RewriteRule ^(.*)$ https://%{HTTP_HOST} [R=301,L] \n\
            RewriteCond %{HTTPS} off \n\
            RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301] \n\
            RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC] \n\
            RewriteRule ^ https://%1%{REQUEST_URI} [R=301,L] \n\
        </VirtualHost> \n\
        <VirtualHost *:443> \n\
            Protocols h2 http/1.1 \n\
            SSLEngine on \n\
            SSLCertificateFile /etc/apache2/ssl/cert.pem \n\
            SSLCertificateKeyFile /etc/apache2/ssl/cert-key.pem \n\    
            DocumentRoot /srv/www/wordpress \n\
            <Directory /srv/www/wordpress> \n\
                Options FollowSymLinks \n\
                AllowOverride Limit Options FileInfo \n\
                DirectoryIndex index.php \n\
                Require all granted \n\
            </Directory> \n\
            <Directory /srv/www/wordpress/wp-content> \n\
                Options FollowSymLinks \n\
                Require all granted \n\
            </Directory> \n\
        </VirtualHost> "  >> /srv/backup/apache2/sites-available/wordpress.conf \n\
    fi \n\
    if [ ! -f "/etc/apache2/sites-available/wordpress.conf" ]; then \n\
            #For now only copying wordpress.conf
            cp -f /srv/backup/apache2/sites-available/wordpress.conf /etc/apache2/sites-available/wordpress.conf \n\
    fi \n\
    if [ ! -f "/etc/apache2/ssl/cert.pem" ]; then \n\
        mkdir -p /etc/apache2/ssl \n\
        cd /etc/apache2/ssl \n\
        openssl req -x509 -newkey rsa:4096 -keyout cert-key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname" \n\
    fi \n\
    if [ ! -d "/srv/www/wordpress/wp-admin" ]; then \n\
        cp -rf /srv/backup/wordpress /srv/www \n\
        chown -R www-data:www-data /srv/www \n\   
    fi \n\
    a2ensite wordpress \n\
    /usr/sbin/apache2ctl start \n\
    /usr/local/bin/docker-entrypoint.sh $1 ' > /usr/local/bin/mariadb-wp-entrywrapper.sh
RUN chmod +x /usr/local/bin/mariadb-wp-entrywrapper.sh \
    && a2enmod rewrite \
    && a2enmod ssl \
    && a2dissite 000-default \
    && a2dissite default-ssl.conf \
    && sed -i -r 's@ErrorLog .*@ErrorLog /dev/stderr@i' /etc/apache2/apache2.conf \
    && sed -i -r 's@CustomLog .*@CustomLog /dev/stdout combined@i' /etc/apache2/conf-available/other-vhosts-access-log.conf \
    && echo "Customlog /dev/stdout combined" >> /etc/apache2/apache2.conf

ENV MARIADB_DATABASE=db
ENV MARIADB_USER=user
ENV MARIADB_PASSWORD=Welcome1
ENV MARIADB_ROOT_PASSWORD=Welcome1

VOLUME /srv/www/wordpress
VOLUME /etc/apache2/ssl
VOLUME /etc/apache2/sites-available
###
VOLUME /etc/phpmyadmin
#VOLUME /var/lib/mysql #From base image

EXPOSE 3306
EXPOSE 80
EXPOSE 443
CMD ["mariadbd"]
ENTRYPOINT ["mariadb-wp-entrywrapper.sh"]
