# Installation Kubernetes

## Prérequis 

- docker
- machines compatible deb/rpm
- 2Go min
- 2 proc minimum pour le master
- connectivité entre toutes les machines du cluster

https://kubernetes.io/fr/docs/setup/production-environment/tools/kubeadm/_print/#:~:text=Kube%2Drouter%20fournit%20un%20r%C3%A9seau,consulter%20le%20guide%20d'installation.

## Configuration pré-initialisation

### Trafic ponté

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```
### Desactivation du swap

Pour le bon fonctionnement de kubernetes, il faut desactiver le swap.

```bash
swapoff -a
vim /etc/fstab #on supprime la ligne de swap
mount -a

#on verifie avec 
df -h 
```

### Port requis 

Node master

| Protocole | Direction | Port | Pour | Par |
|--- | :-:| :-: | :-: | --:|
| TCP| entrant | 6443* | Kubernetes api server| tous|
| TCP| entrant | 2379-2380 | ETCD server client API | kube-api server,etcd|
| TCP| entrant | 10250 | Kubelet API | lui-meme,Control plane |
| TCP | entrant | 10251 | kube-scheduler | lui-meme |
|TCP|entrant|10252|kube-controler-manager|lui-meme|

Node workers

| Protocole | Direction | Port | Pour | Par |
|--- | :-:| :-: | :-: | --:|
|TCP|entrant|10250|Kubelet API|lui-meme, control plane|
|TCP|entrant|30000-32767|nodeport services| eux-meme|


### Installation des outils kubernetes

On récupère la clé.

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
```

On configure le repo dans la liste des repos 

```bash
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
```

On installe les packets de kubernetes (kubelet va effectué plusieurs redémarrage): 

```bash
sudo apt install kubelet kubeadm kubectl
```

### Installation du CRI (Controller runtime)

Nous allons utiliser cri-docker.

```bash
#on recupère le cri
git clone https://github.com/Mirantis/cri-dockerd.git

#on installe go pour faire compiler notre cri
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
```

## Initialisation du master

### Création du cluster

On initialise le cluster.

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16 -cri-socket /var/run/cri-dockerd.sock
```

avec : 
- cri-socket : le socket de notre cri (on les retrouve dans **/var/run**)
- pod-network-cidr : range d'ip pour les adresses ip des pods

Pour que notre utilisateur non-admin puisse faire fonctionner correctement kubectl : 
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Installation Réseau de Pods 

Nous allons utiliser le réseau de pods Calico, qui est réputé pour etre le meilleur.

```bash
wget https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/calico.yaml

vim calico.yaml

#on modifie le paramètres suivant : 
name: CALICO_IPV4POOL_CIDR
value: "10.244.0.0/16"


#on lance l'installation du réseau
kubectl apply -f calico.yaml
```

**ATTENTION** : Les commandes kubectl et kubeadm fonctionne avec un fichier config qui se trouve dans un dossier **.kube** dans le home directory. Dans notre cas, les commandes doivent se lancer avec l'utilsateur **admuser**.

### Création des requirements sur le master

Pour que les nodes se connectent, il leur faut un token et le hash du master.<br>
Pour obtenir le hash, il faut faire : 

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null |    openssl dgst -sha256 -hex | sed 's/^.* //'
```

Pour les tokens, il faut faire : 

```bash
#lister les tokens
kubeadm token list
#creer un token
kubeadm token create
```

Les tokens ont une durée de vie de 24h.
## Installation du Worker

Il faut que la configuration pré-initialisation ait été faite sur le serveur.
### Connexion Au Cluster

On fait le join : 

```bash
kubeadm join <ip> --token <token> --hash sha256:<hash> --cri-socket /var/run/cri-dockerd.sock
```

### Vérification

On peut verifier que les workers sont bien installé et connecté au cluster, il faut aller sur le master et tapez la commande : 

```bash
kubectl get node
```