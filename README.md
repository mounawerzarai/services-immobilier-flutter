# Services Immobilier — version Flutter

Application mobile de petites annonces immobilières en Tunisie : on y publie un bien à vendre ou à louer, on recherche et on filtre les annonces, on les voit sur une carte, on les met en favoris et on écrit au vendeur en temps réel.

Cette version est écrite en **Flutter (Dart)**. Une version jumelle en **React Native** a les mêmes fonctionnalités et utilise la même base Firebase : [services-immobilier-rn](https://github.com/mounawerzarai/services-immobilier-rn).

Projet de 3e année DSI, ISET Tozeur.

## Équipe

| Nom |
|---|
| Mounawer Zarai |
| Yassine Fekih |
| Yassmine Gaabel |
| Tayssier |

## Fonctionnalités

- Inscription, connexion, mot de passe oublié, profil modifiable
- Publier une annonce avec 1 à 8 photos et sa position, la modifier, la supprimer, la marquer vendue ou louée
- Liste paginée et fiche détaillée avec carrousel de photos
- Recherche texte (sans accents), filtres (vente ou location, type, ville, prix, pièces) et tri par date ou prix
- Carte avec un marqueur par annonce, et recherche « autour de moi » avec un rayon en km
- Favoris
- Messagerie en temps réel, badge de messages non lus, alerte dans l'appli à l'arrivée d'un message
- Bandeau « hors ligne » et compteur de caractères dans le chat

## Technologies

| Brique | Choix |
|---|---|
| Interface | Flutter 3.50, Dart |
| Navigation | `go_router` |
| Authentification et base de données | Firebase : `firebase_auth`, `cloud_firestore` |
| Photos | Cloudinary (envoi non signé, paquet `http`) ; seule l'adresse de l'image est stockée dans Firestore |
| Carte | `flutter_map` avec fond OpenStreetMap (aucune clé payante) |
| Position | `geolocator` |

Le projet utilise le plan gratuit **Firebase Spark** : pas de Firebase Storage, pas de Cloud Functions. Il n'y a donc pas de notification push vers une appli fermée ; une alerte s'affiche dans l'appli ouverte.

## Prérequis

- Flutter (le projet a été développé avec Flutter 3.50) et son SDK Dart
- Android Studio avec un émulateur Android (ou un téléphone en mode développeur), le SDK Android et le NDK
- Git

La configuration Firebase (`lib/firebase_options.dart`, `android/app/google-services.json`) est déjà dans le dépôt : il n'y a rien à renseigner.

## Installation et lancement

```bash
git clone https://github.com/mounawerzarai/services-immobilier-flutter.git
cd services-immobilier-flutter
git checkout develop
flutter pub get
flutter run --android-skip-build-dependency-validation
```

L'option `--android-skip-build-dependency-validation` est nécessaire tant que le plugin Android du projet (AGP 9.1.0) est plus ancien que le minimum demandé par Flutter 3.50 (9.1.1). La mise à jour du plugin est prévue à part.

### Problèmes connus

- **NDK incomplet** (`source.properties` manquant, téléchargement interrompu) : supprimer le dossier `ndk/<version>` du SDK Android, puis le réinstaller depuis le SDK Manager.
- **L'émulateur ne démarre pas** (code de sortie 1) : arrêter les processus `qemu`, `emulator` et `adb`, supprimer les fichiers `.lock` du dossier de l'émulateur, puis relancer.
- **`INSTALL_FAILED_UPDATE_INCOMPATIBLE`** : la version React Native a le même identifiant de paquet. Désinstaller l'autre appli : `adb uninstall com.servicesimmobilier.services_immobilier`.
- **Erreurs de connexion sur l'émulateur** : vérifier que l'émulateur a internet, saisir l'email sans espace et désactiver la correction automatique du clavier.

## Vérifier le code

```bash
flutter analyze
flutter test
```

Les tests automatiques couvrent le calcul des distances de la recherche « autour de moi » (`test/geo_test.dart`) et les formats de la messagerie (`test/messaging_format_test.dart`). Le reste de l'appli est validé par un plan de 77 tests manuels (`plan-de-tests.xlsx`, fourni avec le rapport).

## Base de données Firestore

Les règles de sécurité et les index sont déployés depuis le dépôt React Native (dossier `firebase/`), car les deux applications partagent la même base.

| Collection | Contenu | Qui peut écrire |
|---|---|---|
| `users/{uid}` | profil | le propriétaire |
| `users/{uid}/favorites/{listingId}` | favoris | le propriétaire |
| `listings/{id}` | annonces | le vendeur |
| `conversations/{id}` | conversation entre deux personnes pour une annonce | les deux participants |
| `conversations/{id}/messages/{id}` | messages | les deux participants |

Les annonces se lisent sans compte. Firestore n'a pas de recherche plein texte : l'appli charge les 200 annonces disponibles les plus récentes et filtre côté appareil.

## Structure du projet

```
lib/
├── core/              thème, routes
├── data/
│   ├── models/        User, Listing, Conversation
│   └── services/      authentification, annonces, profil
├── features/
│   ├── auth/          écran de connexion et validation
│   ├── favorites_profile/  profil, modification, avatar
│   ├── listings/      carte d'annonce, carrousel, formats
│   ├── search/        recherche, filtres, tri
│   ├── map/           carte, distance, « autour de moi »
│   ├── messaging/     formats et noms des interlocuteurs
│   ├── notifications/ alertes de nouveaux messages
│   └── offline/       bandeau hors ligne
├── screens/           un fichier par écran
├── services/          favoris, messagerie, publication, envoi des photos (Cloudinary)
├── widgets/           éléments d'interface réutilisables
└── main.dart
test/                  tests automatiques
```

Les noms des modules et des écrans sont les mêmes que dans la version React Native, pour comparer les deux applications écran par écran.

## Règles Git

- `main` : versions stables.
- `develop` : intégration du travail en cours.
- `feature/AIFRN-<n°>-<description>` : une branche par ticket, créée depuis `develop`.
- Chaque modification passe par une pull request vers **`develop`** (vérifier la branche de base, GitHub propose `main` par défaut).
- Les messages de commit commencent par la clé Jira, par exemple `AIFRN-41: écran Mes favoris`.

## Suivi du projet

Jira, projet « Application Immobilier (Flutter + React Native) », clé `AIFRN`.
