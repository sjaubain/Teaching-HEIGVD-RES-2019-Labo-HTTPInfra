# Teaching-HEIGVD-RES-2018-Labo-HTTPInfra

## Objectifs

L'objectif de ce laboratoire est de construire pas-à-pas une infrastructure WEB comprenant un reverse proxy, capable de rediriger des requêtes vers un ou plusieurs noeuds statiques ou dynamiques. Les étapes ont été rajoutées à chaque fois dans une nouvelle branche git, créee à partir de la précédente. Les différents noeuds de l'infrastructure ont été empaquetés dans des containers docker. La configuration et le lancement de ces différents containers sont expliqués dans les points suivants.

## Etape 1: Serveur HTTP statique avec apache httpd

Il s'agit ici de démarrer un serveur apache, servant du contenu statique, provenant d'un template bootstrap customisé.

Branche git : **fb-apache-static**

Répertoire : **/docker-images/apache-php-image/**

L'image docker est construite à partir d'une image officielle php-apache. La commande ```COPY content/ /var/www/html``` permet de copier le contenu de notre page statique dans le système de fichier de l'image.

Pour accéder au serveur depuis un navigateur, il est nécessaire de faire du port-mapping. Pour construire l'image, se placer dans le répertoire puis taper

```bash
docker build -t res/apache_static .
```

Lancer ensuite un container

```bash
docker run -d -p 9090:80 --name apache_static res/apache_static
```

Il est ensuite possible d'accéder au serveur via l'adresse `<adresse_machine_docker>:9090`

Pour naviguer dans le système de fichiers du container et observer que le contenu a bien été copié ou pour l'éditer, entrer la commande

```bash
docker exec -it apache_static /bin/bash
```
Notons qu'il est également possible de se connecter au container depuis la machine docker sans port mapping, en récupérant l'addresse ip avec la commande `docker inspect apache_static | grep -i ipaddr` puis en se connectant avec *telnet* par exemple.

## Etape 2: Serveur HTTP dynamique avec express.js

Le second objectif consiste en le lancement d'un serveur *node* servant du contenu dynamique via le module *chance*. À chaque requête, on récupère un payload JSon contenant une matrice générée aléatoirement.

Branche git : **fb-express-dynamic**

Répertoire : **/docker-images/express-image/**

De la même manière que dans l'étape précédente, on copie le fichier source contenant le script à exécuter dans le système de fichiers du serveur node et on construit l'image depuis le répertoire

```bash
docker build -t res/express_dynamic .
```

Puis on lance un container

```bash
docker run -d -p 9191:3000 --name express_dynamic res/express_dynamic
```

Le raisonnement à suivre pour récupérer les payload JSon est similaire à celui expliqué dans l'étape précédente. L'adresse sera `<adresse_machine_docker>:9191/api/matrix/`. On observe bien que le contenu est généré aléatoirement et change à chaque requête.

## Etape 3: Reverse proxy apache (configuration statique)

Le but ici est de construire un reverse proxy comme unique point d'entrée pour nos deux noeuds statique et dynamique. Il est important de souligner la faiblesse d'une telle configuration statique. En effet, les deux adresses IP des containers sont codées "en dur" dans le fichier de configuration que l'on copie dans le filesystem du container empaquetant le reverse proxy. Nous verrons par la suite comment rendre la configuration plus robuste.

Branche git : **fb-reverse-proxy**

Répertoire : **/docker-images/apache-reverse-proxy**

Comme toujours, on construit l'image de notre reverse proxy, en se plaçant dans le répertoire correspondant

```bash
docker build -t res/apache_rp .
```

On exécute dans un premier temps nos deux containers statique et dynamique sans port mapping puis on lance un container avec l'image du reverse proxy

```bash
docker run -d -p --name apache_rp 8080:80 res/apache_rp
```

Notons qu'il est indispensable de spécifier ici un port mapping pour pouvoir accéder au reverse proxy depuis l'extérieur de la machine docker. Il s'agira de l'unique point d'entrée vers nos deux containers, qui ne seront eux pas joignables depuis le navigateur. En effet, c'est le reverse proxy qui se chargera d'"aiguiller" les requêtes. Une résolution DNS est nécessaire pour accéder le serveur via l'adresse *demo.res.ch*.

## Etape 4: Requêtes AJAX avec JQuery

Le but de cette étape est d'inclure la liste de matrices provenant du noeud dynamique au sein de la page html provenant du noeud statique, et ce grâce à des requêtes AJAX émises par le navigateur (client). Pour ce faire, il est impératif d'utiliser un reverse proxy pour ne pas violer la *same origin policy*.

Branche git : **fb-ajax-jquery**

Répertoire : **/docker-images/apache-php-image/**

Un script présent dans le dossier *js* du contenu de la page permet de recevoir le payload JSon puis de l'insérer dans une balise html choisie gràce à la ligne

```js
$(".insert-text").text(m);
```

Toutes les balises ayant pour identifiant *insert-text* se rempliront alors du contenu dynamique obtenu. Si on utilise par exemple les outils de développement de Chrome, on observe que les requêtes AJAX proviennent bel et bien du navigateur et ne sont pas émises d'un noeud à l'autre.

## Etape 5: Configuration dynamique du reverse proxy

Comme nous l'avons vu dans l'étape 4, la configuration est fragile car les adresses IP des noeuds sont codées "en dur" dans le fichier de configuration. Pour remédier à ce problème, on utilise des variables d'environnement que le flag `-e` de docker permet de définir au sein du container.

Branche git : **fb-dynamic-configuration**

Répertoire : **/docker-images/apache-reverse-proxy/**

Nous utilisons notre propre fichier *apache2-foreground*, dans lequel les commandes permettant de définir de nouvelles variables d'environnement `$STATIC_APP` et `$DYNAMIC_APP` ainsi que la commande permettant à un template php récupérant la valeur de ces variables d'être copié dans le fichier principal de configuration des adresses des noeuds du proxy.

De cette manière, lors de l'exécution de *apache2-foreground* dans le container php, les adresses seront récupérées puis attribuées dynamiquement. Pour s'en convaincre, on peut lancer un nombre arbitraire de fois les containers statiques et dynamiques, spécifier un nom pour les derniers, et enfin lancer le container du reverse proxy en instanciant les variables d'environnement avec les valeurs des adresses récupérées.

```bash
# Lancement des containers
docker run -d res/apache_static
...
docker run -d --name apache_static res/apache_static

docker run -d res/express_dynamic
...
docker run -d --name express_dynamic res/express_dynamic

# Recuperation des adresses des containers statiques et dynamiques
docker inspect apache_static | grep -i ipaddr
docker inspect express_dynamic | grep -i -ipaddr

# Lancement du container reverse proxy avec le flag -e
# Necessite de reconstruire l'image res/apache_rp
docker run -d -e STATIC_APP=<static_ip>:80 -e DYNAMIC_APP=<dynamic_ip>:3000 -–name apache_rp -p 8080:80 res/apache_rp
```

On constate que tout fonctionne quel que soit le nombre de containers lancés. Cette démarche est cependante fastidieuse et un script bash présent à la racine permet d'automatiser toute cette procédure.

## Etape 6 (additionnelle): Ajout du load-balancing au Reverse proxy

Branche git : **fb-load-balancing**

Répertoire : **/docker-images/apache-reverse-proxy**

Pour cette étape de répartition des charges au sein d'un groupe de noeuds statiques et dynamiques, nous choisissons de définir deux variables d'environnement supplémentaires pour avoir deux noeuds statiques et deux noeuds dynamiques. A la manière de la configuration dynamique de l'étape précédente, on complète le template php ainsi que le fichier de configuration en mode load-balancing sans oublier d'ajouter au Dockerfile la commande pour activer le mode nécessaire et on lance le container *apache_rp* après avoir reconstruit l'image.

Grâce à `docker logs`, on constate que les requêtes sont bien réparties entre les différents noeuds. En outre, si un des container est tué, le service continue de fonctionner en utilisant l'autre. Un script présent dans le répertoire permet d'automatiser le lancement des quatre noeuds ainsi que du reverse proxy.
