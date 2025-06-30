# Configuration Google Maps pour Afrilyft

## Étapes pour configurer Google Maps

### 1. Obtenir une clé API Google Maps

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez l'API Maps SDK for Android et Maps SDK for iOS
4. Créez des clés API :
   - Une clé pour Android
   - Une clé pour iOS

### 2. Configurer les clés API

#### Pour Android :
1. Ouvrez le fichier `android/app/src/main/AndroidManifest.xml`
2. Remplacez `YOUR_GOOGLE_MAPS_API_KEY` par votre vraie clé API Android

#### Pour iOS :
1. Ouvrez le fichier `ios/Runner/AppDelegate.swift`
2. Remplacez `YOUR_GOOGLE_MAPS_API_KEY` par votre vraie clé API iOS

#### Configuration centralisée :
1. Ouvrez le fichier `lib/config/maps_config.dart`
2. Remplacez les valeurs par vos vraies clés API

### 3. Sécuriser les clés API

⚠️ **IMPORTANT** : Ne commitez jamais vos vraies clés API dans Git !

1. Ajoutez les fichiers de configuration à `.gitignore`
2. Utilisez des variables d'environnement ou un fichier de configuration local
3. Restreignez vos clés API dans Google Cloud Console :
   - Limitez par package name pour Android
   - Limitez par bundle ID pour iOS
   - Activez la facturation pour éviter les limitations

### 4. Tester la configuration

1. Exécutez `flutter clean`
2. Exécutez `flutter pub get`
3. Lancez l'application sur un appareil ou émulateur
4. Naviguez vers la page d'aperçu du trajet pour voir la carte

## Fonctionnalités implémentées

- ✅ Carte Google Maps interactive
- ✅ Marqueurs pour point de départ et d'arrivée
- ✅ Ligne de trajet entre les points
- ✅ Marqueurs pour les chauffeurs à proximité
- ✅ Bouton de localisation utilisateur
- ✅ Ajustement automatique de la vue pour afficher tous les marqueurs

## Dépannage

### La carte ne s'affiche pas
- Vérifiez que vos clés API sont correctes
- Vérifiez que l'API Maps SDK est activée
- Vérifiez les permissions de localisation

### Erreur de clé API
- Vérifiez que la clé API est correctement configurée
- Vérifiez les restrictions de la clé API dans Google Cloud Console
- Vérifiez que la facturation est activée

### Permissions de localisation
- Assurez-vous que les permissions sont accordées sur l'appareil
- Vérifiez que les permissions sont déclarées dans le manifest 