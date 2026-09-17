# Timeline Duel

A Flutter trivia and collection game about historical figures. Players answer
quiz questions, collect cards, unlock question types, and play tactical battles.

## Local development

```sh
flutter pub get
flutter test
flutter analyze
flutter run
```

The app supports German and English. It uses the device language on first start;
the language can be changed from the in-app menu.

## Release checklist

- Configure real AdMob unit IDs. Test IDs are intentionally used in development.
- Create every product ID from `lib/monetization/store_catalog.dart` in Google
  Play Console before publishing.
- Deploy `firestore.rules` and `firestore.indexes.json` to the intended Firebase
  project.
- Keep anonymous Firebase Authentication enabled while the current online
  identity flow is in use.
- Run `flutter analyze` and `flutter test` in CI before every release.

## Security note

Client-side purchase callbacks are not a sufficient source of truth for a
production economy. Before enabling real-money products, verify Google Play
purchase tokens in a trusted backend and grant coins/packs there. Likewise,
match resolution and rating changes should move to trusted server code before
competitive online play is launched.
