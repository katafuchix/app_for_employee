# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter employee app with Firebase integration. Main application code lives in `lib/`, with the entrypoint in `lib/main.dart` and generated Firebase config in `lib/firebase_options.dart`.

Feature code is organized under `lib/features/` by domain such as `auth/`, `home/`, `manual/`, `message/`, `operation/`, `shift/`, and `todo/`. Keep related UI, models, repositories, and controllers inside the same feature folder. Shared assets live in `assets/images/` and `assets/launcher_icon/`. Platform runners are in `android/` and `ios/`. Widget tests currently live in `test/`.

## Build, Test, and Development Commands
- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: launch the app on the connected simulator or device.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run the automated test suite in `test/`.
- `dart run build_runner build --delete-conflicting-outputs`: regenerate `*.g.dart` files for Riverpod and other codegen.
- `flutter build apk` or `flutter build ios`: create production builds for each platform.

## Coding Style & Naming Conventions
Follow Dart defaults: 2-space indentation, trailing commas where formatter-friendly, and one public class per file when practical. Use `snake_case` for file names like `login_page.dart`, `PascalCase` for types, and `camelCase` for variables and methods.

Use `snake_case` for all field keys saved to Firestore and all Firebase Storage folder names. Dart properties and local variables may remain `camelCase`, but any persisted Firebase key or path segment such as `submission_image_ids` or `todo_execution` must be `snake_case`.

Do not edit generated files such as `*.g.dart` or `lib/firebase_options.dart` by hand. Prefer feature-local repositories or services over direct Firebase calls from widgets.

## Testing Guidelines
Use `flutter_test` for widget and unit coverage. Name tests with the `_test.dart` suffix and mirror the feature being tested, for example `test/todo/todo_page_test.dart`. Add or update tests for behavior changes in controllers, repositories, and user-visible flows before opening a PR.

## Commit & Pull Request Guidelines
Recent history uses short imperative subjects, often with prefixes like `add:`, `remove:`, `change`, `build`, or `chore:`. Keep commit messages concise and scoped to one change.

Pull requests should include a short summary, impacted screens or features, linked issue if applicable, and screenshots or recordings for UI changes. Note any Firebase, asset, or generated-file updates so reviewers can validate them quickly.

## Configuration Notes
Firebase platform config files are committed under `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`. Treat credentials carefully, avoid logging sensitive data, and verify environment-specific changes before release builds.
