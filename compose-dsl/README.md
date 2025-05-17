# Compose DSL Module

This module provides a minimal Jetpack Compose implementation of the DSL engine
used in the Swift version of the project. The architecture mirrors the iOS
implementation with packages for `commands`, `core`, `helper`, `operators` and
`ui/components`. The main classes (`DSLContext`, `DSLInterpreter`,
`DSLAppEngine`) live under the `core` package.

## Building and Running

1. Open the `compose-dsl` directory in Android Studio.
2. Ensure that the Android Gradle Plugin and Kotlin version support Jetpack
   Compose (AGP 8+ recommended).
3. Build and run the `sample` module on an Android device or emulator.
   The sample `MainActivity` loads `app.compiled.json` from the Android assets
   and renders the resulting UI.
4. Make sure the `src/main/assets` directory contains `app.compiled.json`. A
   copy of the file from the Swift module is included for convenience.

A basic `build.gradle` file is expected with Compose dependencies. For brevity,
this repository does not ship a full Gradle wrapper.

## Limitations

* Only a subset of the operators from `DLSKit/Operators` has been implemented
  in Kotlin. Additional operators can be registered following the same pattern.
* Component modifiers are minimal and only cover basic layout. More modifiers
  can be added by extending the component builders.
* JSON parsing relies on `org.json` and expects an `app.compiled.json` file in
  the app assets folder.

