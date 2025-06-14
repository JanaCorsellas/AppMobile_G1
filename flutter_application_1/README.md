# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


##  Integració notificacions push a l'aplicació (amb Firebase)

Instal·lat i implementat el servei de Firebase per notificacions push a l'aplicació.


## Com utilitzar FIREBASE al projecte per les notificacions push amb Cloud Messaging

1. Insal·la dependències (flutter pub get) dins la carpeta del projecte ...\AppMobile_G1\flutter_application_1>
2. Aconsegueix els arxius de configuració (sol·licitar-los a la Jana). Necessitaràs:
- `google-services.json` per **Android** --> copiar a android/app/
- `GoogleService-Info.plist` per **iOS** --> copiar a ios/Runner/
- `your-firebase-service-account.json` (en `src/firebase/`) **només si necessites executar el backend o funcions administratives** --> copiar al backend a src/firebase/

