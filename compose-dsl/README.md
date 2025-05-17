# Compose DSL Module

This module ports a subset of the SwiftUI `DLSKit` DSL to Jetpack Compose.  The
package layout mirrors the Swift source with folders:

- `core` – context, interpreter and registries
- `commands` – command implementations
- `operators` – expression operators
- `ui/components` – composable UI widgets

A minimal `AndroidManifest.xml` and an `app.compiled.json` asset are provided so
the module can be opened directly in Android Studio.

## Building and Running

1. Open the `compose-dsl` directory in Android Studio.
2. Ensure that your environment supports Compose (AGP 8+ and Kotlin 1.9+).
3. Build and run on an emulator or device. `MainActivity` will load the JSON UI
   from `src/main/assets/app.compiled.json` and render it.

## Limitations

* Only a few modifiers (padding, frame, backgroundColor) are implemented.
* Operators mirror only a subset of the Swift version.
* Gradle wrapper files are omitted for brevity.
