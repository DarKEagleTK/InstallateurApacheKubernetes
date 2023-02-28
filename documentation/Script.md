# Script D'installation de site web customiser sur kubernetes

## Prérequis

- Installation de kubernetes effectué
- Utilisateur avec les droits docker

## Docker

On commence par créé un repo sur docker.hub. 

On connecte ensuite notre compte a notre machines.

```bash
docker login
```

On crée ensuite notre image docker : 

Dockerfile : 

On crée l'image et on l'envoie sur le repo docker hub : 

```bash
docker build -t <nom>:v1.0 .
docker tag <nom>:v1.0 <nom_utilisateur>/<nom_repo>:<nom_image>
docker push <nom_utilisateur>/<nom_repo>:<nom_image>
```

On configure le kubernetes pour récupérer les images depuis un repo privée : 

```bash

```