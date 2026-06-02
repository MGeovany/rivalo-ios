# Rivalo Card Assets

Assets por capas para armar las cartas de perfil en runtime.

## Estructura por elo

Cada carpeta contiene:

- `background.png`: fondo oscuro y textura del elo.
- `photo-mask-soft.png`: máscara opcional para recortar suavemente la imagen del usuario.
- `frame.png`: marco ornamental con transparencia.
- `fx-overlay.png`: brillos y destellos con transparencia.
- `preview-flat.png`: referencia visual aplanada.
- `manifest.json`: orden de capas y áreas seguras sugeridas.

## Orden recomendado

1. `background.png`
2. Imagen del usuario
3. `photo-mask-soft.png` como máscara de la imagen
4. `frame.png`
5. Textos y estadísticas renderizados desde código
6. `fx-overlay.png`

## Nota

Los assets se generaron como base visual para prototipo. Conviene revisar manualmente los bordes transparentes y optimizarlos antes de publicación final.
