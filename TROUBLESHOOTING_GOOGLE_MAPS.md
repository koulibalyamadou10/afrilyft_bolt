# Dépannage Google Maps - Erreur API Key

## Erreur rencontrée
```
API key not found. Check that <meta-data android:name="com.google.android.geo.API_KEY" android:value="your API key"/> is in the <application> element of AndroidManifest.xml
```

## Solutions possibles

### 1. Vérifier la clé API dans Google Cloud Console

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet
3. Allez dans "APIs & Services" > "Credentials"
4. Vérifiez que votre clé API existe et est active
5. Cliquez sur votre clé API pour voir les détails

### 2. Activer les APIs nécessaires

Dans Google Cloud Console, activez ces APIs :
- **Maps SDK for Android**
- **Maps SDK for iOS**
- **Places API** (optionnel, pour les suggestions d'adresses)

### 3. Configurer les restrictions de la clé API

1. Dans les détails de votre clé API, allez dans "Application restrictions"
2. Pour Android : Sélectionnez "Android apps" et ajoutez votre package name
3. Pour iOS : Sélectionnez "iOS apps" et ajoutez votre bundle ID

### 4. Vérifier la facturation

1. Allez dans "Billing" dans Google Cloud Console
2. Assurez-vous qu'un compte de facturation est lié à votre projet
3. Google Maps nécessite un compte de facturation actif

### 5. Tester avec une clé API de test

Créez une nouvelle clé API sans restrictions pour tester :
1. Allez dans "Credentials"
2. Cliquez sur "Create Credentials" > "API Key"
3. Utilisez cette clé temporairement pour tester

### 6. Vérifier le manifest Android

Assurez-vous que la clé API est bien dans le bon endroit :
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="VOTRE_CLE_API" />
    <!-- autres éléments -->
</application>
```

### 7. Nettoyer et reconstruire

```bash
flutter clean
flutter pub get
flutter run
```

### 8. Tester sur un appareil physique

Les cartes Google Maps peuvent ne pas fonctionner correctement sur les émulateurs. Testez sur un appareil Android réel.

### 9. Vérifier les permissions

Assurez-vous que ces permissions sont dans le manifest :
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 10. Alternative temporaire

Si Google Maps ne fonctionne toujours pas, nous pouvons utiliser :
- Une carte statique
- OpenStreetMap
- Une image de carte avec des marqueurs simulés

## Test rapide

Utilisez le bouton "Test Google Maps" dans l'application pour tester si la carte se charge correctement.

## Contact

Si le problème persiste, vérifiez :
1. Les logs de l'application pour plus de détails
2. La console Google Cloud pour les erreurs d'API
3. Les quotas et limites de votre projet 