
# QuickServe Flutter Auth Drop-in

**What this includes**
- Role-based login & register (consumer/vendor/rider) + email verify screen
- Splash that auto-routes based on saved token & role
- Placeholder home screens for each role
- API client wired to http://192.168.219.104:5000

**Dependencies to add to pubspec.yaml**

```yaml
dependencies:
  http: ^1.2.2
  shared_preferences: ^2.3.2
```

**How to use**
1) Extract this `lib/` into your Flutter project's `lib/` (replace existing files if prompted).
2) Ensure your backend is running and reachable from phone over Wi‑Fi.
3) In Android Studio/VS Code: `flutter clean && flutter pub get && flutter run`.
