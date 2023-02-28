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

if [ $# -eq 0 ]; then help; fi

domain=$1
if [ ! -d "/home/kubemaster/site/$domain" ]; then
    mkdir -p /home/kubemaster/site/$domain/apache
    mkdir -p /home/kubemaster/site/$domain/file
    mkdir -p /home/kubemaster/site/$domain/certificats
    mkdir -p /home/kubemaster/site/$domain/kubeconf
fi
unzip $2 -d /home/kubemaster/site/$domain/file



echo "apiVersion: v1
kind: Service
metadata:
  name: httpd-$domain
  namespace: default
spec:
  type: NodePort
  selector:
    app: httpd_app_$domain
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30004
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deployment-$domain
  namespace: default
  labels:
    app: httpd_app_$domain
spec:
  selector:
    matchLabels:
      app: httpd_app_$domain
  template:
    metadata:
      labels:
        app: httpd_app_$domain
    spec:
      containers:
        - name: httpd-container-$domain
          image: httpd:latest
          ports:
            - containerPort: 80

" > /home/kubemaster/site/$domain/kubeconf/