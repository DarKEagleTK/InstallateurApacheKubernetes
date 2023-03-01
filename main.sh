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
if [ -z "$2" ]; then help; fi

domain=$1
name=$(echo $domain | cut -d "." -f1)
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
  name: httpd-${name}
  namespace: default
spec:
  type: NodePort
  selector:
    app: httpd_app_${name}
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30004
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deployment-${name}
  namespace: default
  labels:
    app: httpd_app_${name}
spec:
  selector:
    matchLabels:
      app: httpd_app_${name}
  template:
    metadata:
      labels:
        app: httpd_app_${name}
    spec:
      containers:
        - name: httpd-container-${name}
          image: httpd:latest
          ports:
            - containerPort: 80

" > /home/kubemaster/site/$domain/kubeconf/kubeconf.yaml

if [ -e /home/kubemaster/site/$domain/kubeconf/kubeconf.yaml ]; then
    kubectl apply -f /home/kubemaster/site/$domain/kubeconf/kubeconf.yaml
else
    echo "erreur : fichier kubeconf.yaml non disponible"
fi
sleep 10
get_pod=$(kubectl get pod | grep httpd-deployment-$name | awk '{print $1}')

for file in /home/kubemaster/site/$domain/file/*
do
    kubectl cp $file $get_pod:/usr/local/apache2/htdocs/
    echo "done"
done