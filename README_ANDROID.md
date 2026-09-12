# Aliens Invasion v40 — LÖVE 2D Android

Esta versión corrige el error de Android:

`[love "boot.lua"]:328: No code to run`

## Corrección importante

El APK ya no depende de que LÖVE encuentre y descomprima `game.love` dentro del APK. El workflow coloca directamente el árbol del juego en `app/src/embed/assets/`, de modo que el APK final contiene:

- `assets/main.lua`
- `assets/conf.lua`
- `assets/src/...`
- `assets/assets/...`

El workflow además inspecciona el APK y **falla la compilación si `assets/main.lua` no existe en la raíz del juego**.

## Motor

- LÖVE 2D Android 11.5 Hotfix 1 (`11.5a`).
- APK debug instalable.
- Pantalla horizontal.
- Resolución lógica 576×320.
- Controles táctiles.
- Audio y gráficos incluidos.
- ENet/LAN se desactiva de forma segura si el módulo nativo no está disponible en Android.

## GitHub Actions

Sube el contenido del ZIP al repositorio y ejecuta:

**Actions → Build Aliens Invasion Android APK → Run workflow**

Descarga el artefacto:

`aliens-invasion-v40-android`

Dentro estará:

`aliens-invasion-v40-debug.apk`
