# Compose DSL Module

This module provides a minimal Jetpack Compose implementation of the DSL engine
used in the Swift version of the project. The architecture mirrors the iOS
implementation with `DSLContext`, `DSLInterpreter`, `DSLAppEngine` and the
corresponding registries for commands, operators and UI components.

## Building and Running

1. Open the `compose-dsl` directory in Android Studio.
2. Ensure that the Android Gradle Plugin and Kotlin version support Jetpack
   Compose (AGP 8+ recommended).
3. Build and run the `sample` module on an Android device or emulator.
   The sample `MainActivity` loads `app.compiled.json` from the Android assets
   and renders the resulting UI.

A basic `build.gradle` file is expected with Compose dependencies. For brevity,
this repository does not ship a full Gradle wrapper. The `app.compiled.json`
used by the sample is copied from the Swift project and placed under
`src/main/assets` so it is bundled with the Android app.

## Limitations

* Only a subset of the operators from `DLSKit/Operators` has been implemented
  in Kotlin. Additional operators can be registered following the same pattern.
* Component modifiers are limited to a few basics such as padding, background,
  frame size and corner radius. More modifiers can be added by extending the
  `DSLModifierRegistry`.
* JSON parsing relies on `org.json` and expects an `app.compiled.json` file in
  the app assets folder.

