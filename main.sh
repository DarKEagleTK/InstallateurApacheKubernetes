#!/bin/bash


help()
{
    echo "Utilitaire Installateur Web kubernetes"
    echo ""
	echo "Utilisation : $0 <domain> <file> [<params>]"
    echo ""
    echo "file = zip des fichiers du site"
    echo "domain = nom de domaine à appliquer"
    echo "params :"
    echo "  -c <cert>: zip des certificats sous le nom cert.cer, cert.key et fullchain.cer"
    exit;
}
config()
{
    domain=$1
    DOCUMENTROOT=/var/www/$domain
    DESTINATION="/home/kubemaster/site/$domain/apache/$domain.conf"

    echo "
    <VirtualHost *:80 >
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $DOCUMENTROOT
    ErrorLog /var/log/apache2/$domain.error.log
    CustomLog /var/log/apache2/$domain.access.log combined
    </Virtualhost>" > $DESTINATION
}
config_ssl()
{
    domain=$1
    DOCUMENTROOT=/var/www/$domain
    DESTINATION="/home/kubemaster/site/$domain/apache/$domain.conf"

    echo "
    <VirtualHost *:80 >
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $DOCUMENTROOT
    ErrorLog /var/log/apache2/$domain.error.log
    CustomLog /var/log/apache2/$domain.access.log combined
    </Virtualhost>
    
    <IfModule mod_ssl.c>
    <VirtualHost *:443>
    DocumentRoot $DOCUMENTROOT
    ServerName $domain
    ServerAlias www.$domain
    ErrorLog /var/log/apache2/$domain.error.log
    CustomLog /var/log/apache2/$domain.access.log combined
    SSLCertificateFile /etc/certificats/$domain/cert.cer
    SSLCertificateChainFile /etc/certificats/$domain/fullchain.cer
    SSLCertificateKeyFile /etc/certificats/$domain/cert.key
    </VirtualHost>
    </IfModule>
    " > $DESTINATION
}

if [ $# -eq 0 ]; then help; fi

domain=$1
if [ ! -d "/home/kubemaster/site/$domain" ]; then
    mkdir -p /home/kubemaster/site/$domain/apache
    mkdir -p /home/kubemaster/site/$domain/file
    mkdir -p /home/kubemaster/site/$domain/certificats
    mkdir -p /home/kubemaster/site/$domain/docker-compose
fi
unzip $2 -d /home/kubemaster/site/$domain/file

if [ $3 -eq "-c" ]; then
    unzip $4 -d /home/kubemaster/site/$domain/certificats
    config_ssl $domain
else
    config $domain
fi

echo "
version: '3.8'
services:
    apache:
        container_name: container_$domain
        build:
            dockerfile: /home/kubemaster/utilitaire/Dockerfile
        volumes:
            - /home/kubemaster/site/$domain/apache:/etc/apache2/sites-enabled
            - /home/kubemaster/site/$domain/file:/var/www/$domain
            - /home/kubemaster/site/$domain/certificats:/etc/certificats/
        ports:
            - 80:80
            - 443:443
" > /home/kubemaster/site/$domain/docker-compose/docker-compose.yml