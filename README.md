# Rivalo — iOS

App iOS de Rivalo: seguimiento de rendimiento físico para fútbol amateur.

El jugador inicia un partido desde el Apple Watch y, al terminar, revisa en el iPhone un resumen
visual con métricas como duración, distancia, ritmo cardíaco, velocidad máxima, sprints,
intensidad y su progreso histórico.

## Stack

- SwiftUI
- The Composable Architecture (TCA)
- Autenticación e identidad vía Supabase Auth
- API REST en Go (repositorio `rivalo-server`)

## Repositorios del proyecto

- `rivalo-ios` — app iPhone (este repo)
- `rivalo-watch` — app Apple Watch
- `rivalo-server` — API backend

## Development

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is not committed.

```bash
brew install xcodegen        # once
xcodegen generate            # creates Rivalo.xcodeproj
open Rivalo.xcodeproj
```

Dependencies (The Composable Architecture) are resolved automatically via Swift Package Manager.

Because TCA ships Swift macros, the first build must trust them. In Xcode, accept the macro
trust prompt. From the command line, pass `-skipMacroValidation`:

```bash
xcodebuild -project Rivalo.xcodeproj -scheme Rivalo \
  -destination 'generic/platform=iOS Simulator' -skipMacroValidation build
```

The backend base URL defaults to `http://localhost:8080` and can be overridden with the
`RIVALO_API_BASE_URL` build setting.

## Estado

En desarrollo inicial.
