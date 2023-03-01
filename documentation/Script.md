# Script D'installation de site web customiser sur kubernetes

## Prérequis

- Installation de kubernetes effectué
- package unzip installé
- utilisation du compte ayant des droits sur kubernetes

## explication du code : 

### Le menu help
```bash
help()
{
    echo "Utilitaire Installateur Web kubernetes"
    echo ""
	echo "Utilisation : $0 <domain> <file>"
    echo ""
    echo "file = zip des fichiers du site"
    echo "domain = nom de domaine à appliquer"
    exit;
}

if [ $# -eq 0 ]; then help; fi
if [ -z "$2" ]; then help; fi
```
Ce menu permet de donner un exemple de configuration pour le script.<br>
Il s'agit uniquement de simple echo, et la fonction est lancé dans un seul cas : les paramètres demandé ne sont pas présent.

### La création des variables et dossier nécessaire

```bash
domain=$1
name=$(echo $domain | cut -d "." -f1)
if [ ! -d "/home/kubemaster/site/$domain" ]; then
    mkdir -p /home/kubemaster/site/$domain/file
    mkdir -p /home/kubemaster/site/$domain/kubeconf
fi
unzip $2 -d /home/kubemaster/site/$domain/file
```

Ici, on récupère le nom de domaine, et on crée l'arborescance de dossier utilisé pour la création des dockers. <br>
On crée aussi une varaible ```name``` qui nous permettra de stocker la première partie du nom de domaine pour les noms de service et de deployement kubernetes.<br>
Par exemple, ```google.com``` deviendra ```google```.

### La configuration YAML

```bash
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
```

On génère un fichier yaml qui nous permettra de faire la configuration de notre site web.<br>

Dans la première partie, on génère de quoi crée un service. Ce service nous permettra de faire la gestion des ports entre l'hote et le réseau des containeurs.

La seconde partie génère un deployement. C'est un système qui permet de faire de la haute disponibilité en ralumant automatiquement les containeurs en cas d'arret. On spécifie qu'il sont relier au service crée précédement.<br>
Dans la partie containeur, on configure le containeur qui sera créé, en spécifiant l'image et les ports exposer.

### Application de la configuration et configuration du containeur

#### Application de la configuration

```bash
if [ -e /home/kubemaster/site/$domain/kubeconf/kubeconf.yaml ]; then
    kubectl apply -f /home/kubemaster/site/$domain/kubeconf/kubeconf.yaml
else
    echo "erreur : fichier kubeconf.yaml non disponible"
fi
```

Ici, si le kubeconf existe, on le lance.

#### configuration du containeur

```bash
sleep 10
get_pod=$(kubectl get pod | grep httpd-deployment-$name | awk '{print $1}')

for file in /home/kubemaster/site/$domain/file/*
do
    kubectl cp $file $get_pod:/usr/local/apache2/htdocs/
    echo "done"
done
```

On commence par attendre 10 secondes pour que les containeurs montent correctement.
On récupère ensuite le nom du containeur associer au domaine.
On procède ensuite à une copie des fichiers sur le conteneur pour afficher le site correctement.