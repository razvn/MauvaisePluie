## Mauvise Pluie - MOOC Programmation sur iPhone et iPad

Projet de fin de MOOC programmation sur iPhone et iPad partie 1 - session février 2015

Jeu dans lequel il faut éviter de toucher les asteroides qui tombent le déplacement se fait à l'aide des boutons au bord gauche et droit de l'écran

## Auteur

Razvan - mars 2015

## Remarques

Fait avec XCode 6.3 -> mis à jour pour Swift 1.2

## Spécificités

v1.0b5
- Suppression de l'option de la l'activation de la version NSTimer (elle est vraiment pas à l'hauteur, la classe elle reste pour l'exemple)
- Monsieur Heureux n'est plus heureux quand il se fait touché par un astéroide
- Suppression de l'espace vide en bas du joueur
- Intégration de Fabric pour la distribution de la béta et analyse des crush

v1.0b4 - version initiale GitHub
- licence développer achetée donc j'ai pu tester sur le device ce qui a entraîné plusieurs corrections
    - la version UIDynamic est celle par défaut toutes les modifications ont été faites que dans ce mode. (je laisse la NSTime pour l'exemple je ne compte pas le faire évoluer UIDynamic plus fun)
    - taille des boutons déplacement plus grands on peut utiliser sur toute l'hauteur de l'écran
    - légère indication visuelle de l'appui sur les boutons de déplacement
    - amélioration du déplacement de l'utilisateur (vitesse devrait être constante)
    - récupération du niveau sélectionné lorsqu'on retourne dans les préférence et initialisée avec cette valeur
    - effet parallax plus fort et supprimé des vues préférences et scores (inutile car l'image de fond pas assez visible et ajoute un décalage)

- mis à jour pour XCode 6.3 (donc Swift 1.2)
- changement de nom de projet et refactoring pour publication GitHub

v1.0b3 - version soumise
- ajout d'une version UIDynamics du jeu. Activable depuis les paramètres
- ajout du parallax dans toutes les vues (...j'espère, sans déploiement sur device difficile de dire si ca marche ou pas)

v1.0b2
- sauvegarde des scores après l'arrêt de l'application

v1.0b1
- vitesse de rotation différente pour chaque astéroïde
- déplacement horizontal spécifique à chaque astéroïde 
  - le score augmente que pour les astéroïdes qui sortent pas en bas, ceux qui sortent latéralement ne comptent pas

v1.0b0
- utilisation d'un ViewControler par écran affiché avec passage d'un à l'autre
- utilisation d'un modèle singleton partagé par tous les viewControleurs
- dans les constantes du JeuViewControler on peut activer un mode debug qui permet d'afficher d'info et le contour du jouer et astéroïdes et les rectangles de collision lors de l'impact


## Difficultés

- Début en mode geek (construction manuelle des vues) avec autolayout mais perdu beaucoup de temps sur les écrans hors jeu à essayer de le mettre en place avec beaucoup d'erreurs rencontrées à chaque ajout d'un élement
    - du coup utilisé le mode kindergarden (Storyboard) pour les écrans, ce fut beaucoup plus rapide
- Faire une rotation et un translation en même temps, mais finalement j'ai trouvé
- Collision: à cause de la comparaison d'un rectagle alors que le contenu n'est pas vraiement un rectangle et des fois ce n'était pas évident à l'affichage qu'il y a eu collision
    - du coup j'ai pris une marge de reduction des frames à comparer, pas toujours parfait (contact non visible)
- Parametrage de la vitesse et apparition d'astéroides
    - il a fallu tatoner pour trouver des valeurs à peu près (mais je ne suis pas satisfait car niveau 5 presque injouable-du moins en simulator)
- UIDynamics un peu difficile le déplacement du joueur

## TODOs (ce que j'aurais aimé avoir eu le temps de faire en plus)

- Améliorer les formules de vitesse/apparition (niveau 5 ca va trop vite)
- Grouper les scores par niveau (ou ajouter un facteur multiplicatif en fonction du niveau)
- Voir si on gagne en mémoire en gardant un pool d'asteroides sortis l'écrans et à les utiliser au lieu de créer tout le temps des nouveaux
