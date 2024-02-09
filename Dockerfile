FROM mariadb:10.6

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
    certbot \
    python3-certbot-apache \
    #cron \
    php-zip \
    phpmyadmin -yq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && { \
            echo phpmyadmin phpmyadmin/mysql/admin-user string root; \
            echo phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD; \
            echo phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASSWORD; \
            echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2; \
        } | debconf-set-selections \
    && dpkg-reconfigure -f noninteractive phpmyadmin \
    && echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf \
    && { \
            mkdir -p /backup; \
            curl https://en-ca.wordpress.org/wordpress-6.4.3-en_CA.tar.gz | tar zx -C /backup; \
        } \
    && echo '#!/bin/bash \n\
        set -eo pipefail \n\
        shopt -s nullglob \n\ 
        if [ ! -f "/srv/phpmyadmin/apache.conf" ]; then \n\
            cp -rf /etc/phpmyadmin /srv \n\
        fi \n\
        if [ ! -f "/srv/wp-config/wordpress.conf" ]; then \n\
            mkdir -p /srv/wp-config \n\
            echo " <VirtualHost *:80> \n\
                ServerName ${HOSTNAME} \n\
                ServerAlias www.${HOSTNAME} \n\
                RewriteEngine On \n\
                RewriteCond %{HTTPS} off \n\
                RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301] \n\
                RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC] \n\
                RewriteRule ^ https://%1%{REQUEST_URI} [R=301,L] \n\
            </VirtualHost> \n\
            <VirtualHost *:443> \n\
                ServerName ${HOSTNAME} \n\
                ServerAlias www.${HOSTNAME} \n\
                Protocols h2 http/1.1 \n\
                SSLEngine on \n\
                SSLCertificateFile /srv/ssl/cert.pem \n\
                SSLCertificateKeyFile /srv/ssl/cert-key.pem \n\    
                DocumentRoot /srv/wordpress \n\
                <Directory /srv/wordpress> \n\
                    Options FollowSymLinks \n\
                    AllowOverride Limit Options FileInfo \n\
                    DirectoryIndex index.php \n\
                    Require all granted \n\
                </Directory> \n\
                <Directory /srv/wordpress/wp-content> \n\
                    Options FollowSymLinks \n\
                    Require all granted \n\
                </Directory> \n\
            </VirtualHost> "  >> /srv/wp-config/wordpress.conf \n\
        fi \n\
        if [ -f "/srv/wp-config/wordpress.conf" ]; then \n\
            cp -f /srv/wp-config/wordpress.conf /etc/apache2/sites-available/${HOSTNAME}.conf \n\
        fi \n\
        if [ ! -f "/srv/ssl/cert.pem" ]; then \n\
            mkdir -p /srv/ssl \n\
            cd /srv/ssl \n\
            openssl req -x509 -newkey rsa:4096 -keyout cert-key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname" \n\
        fi \n\
        if [ ! -d "/srv/wordpress/wp-admin" ]; then \n\
            cp -rf /backup/wordpress /srv \n\
            chown -R www-data:www-data /srv \n\   
        fi \n\
        rm -rf /etc/phpmyadmin \n\
        cp -rf /srv/phpmyadmin /etc \n\
        a2ensite ${HOSTNAME} \n\
        /usr/local/bin/docker-entrypoint.sh $1 & \n\
        #service cron start \n\
        /usr/sbin/apache2ctl -D FOREGROUND \n\ 
        ' > /usr/local/bin/mariadb-wp-entrywrapper.sh \
    && chmod +x /usr/local/bin/mariadb-wp-entrywrapper.sh \
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
ENV HOSTNAME=localhost
#ENV MULTI_HOSTNAME=

VOLUME /var/lib/mysql
VOLUME /srv

EXPOSE 3306
EXPOSE 80
EXPOSE 443
CMD ["mariadbd"]
ENTRYPOINT ["mariadb-wp-entrywrapper.sh"]
