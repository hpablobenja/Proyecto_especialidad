# Documentación: Sistema de Descarga y Reproducción Offline de Videos

## 1. Origen Autorizado de Videos

Los videos provienen exclusivamente de **YouTube** como plataforma autorizada. El sistema soporta múltiples formatos de URLs de YouTube:

- **URLs estándar**: `youtube.com/watch?v=VIDEO_ID`
- **URLs cortas**: `youtu.be/VIDEO_ID`
- **URLs embed**: `youtube.com/embed/VIDEO_ID`
- **URLs shorts**: `youtube.com/shorts/VIDEO_ID`
- **ID directo**: Solo el ID de 11 caracteres (ej. `dQw4w9WgXcQ`)

**Validación**: El sistema utiliza expresiones regulares para validar que el ID de video tenga exactamente 11 caracteres alfanuméricos con guiones y guiones bajos: `^[A-Za-z0-9_-]{11}$`

## 2. Paquetes y APIs Utilizados

### 2.1 Descarga de Videos
- **`background_downloader: ^8.5.0`**: Maneja descargas en segundo plano con soporte para pausa/reanudación
- **`youtube_explode_dart: ^2.2.1`**: Extrae URLs de streaming directas de YouTube

### 2.2 Reproducción Local
- **`video_player: ^2.9.2`**: Reproductor nativo para videos almacenados localmente
- **`youtube_player_flutter: ^9.1.1`**: Reproductor para videos online de YouTube

### 2.3 Almacenamiento Local
- **`hive: ^2.2.3`**: Base de datos NoSQL local para metadatos
- **`hive_flutter: ^1.1.0`**: Integración con Flutter
- **`path_provider: ^2.1.1`**: Acceso a directorios del sistema

### 2.4 Sincronización Offline
- **`connectivity_plus: ^5.0.0`**: Monitoreo de conectividad de red

## 3. Formato de Video

### 3.1 Formato de Archivo
- **Contenedor**: MP4
- **Tipo de stream**: MuxedStreamInfo (video + audio combinados en un solo archivo)
- **Calidad**: Selecciona automáticamente la mejor calidad muxed disponible (típicamente 720p o 360p)

### 3.2 Nomenclatura de Archivos
```
{courseId}_{videoId}.mp4
```
Ejemplo: `course_abc123_dQw4w9WgXcQ.mp4`

## 4. Proceso de Descarga

### 4.1 Flujo Completo

1. **Inicialización del Servicio**
   - Abre caja Hive `downloadedVideos` si no está abierta
   - Registra callbacks para progreso y estado de descarga

2. **Resolución de URL Directa**
   - Si la URL es de YouTube, usa `youtube_explode_dart` para obtener el manifest
   - Extrae streams muxed (video+audio)
   - Ordena por calidad y selecciona la mejor disponible
   - Retorna la URL directa de streaming MP4

3. **Preparación del Directorio**
   - Obtiene directorio de documentos de la aplicación: `getApplicationDocumentsDirectory()`
   - Crea subdirectorio `videos/` si no existe
   - Ruta completa: `{applicationDocuments}/videos/{courseId}_{videoId}.mp4`

4. **Creación de Registro en Hive**
   - Crea entidad `DownloadedVideoHive` con estado inicial `downloading`
   - Almacena en caja Hive con key = `videoId`

5. **Enqueue de Descarga**
   - Configura `DownloadTask` con:
     - `taskId`: videoId
     - `url`: URL directa de streaming
     - `filename`: nombre del archivo
     - `directory`: `videos`
     - `baseDirectory`: `BaseDirectory.applicationDocuments`
     - `updates`: `Updates.statusAndProgress`
     - `allowPause`: true
     - `retries`: 3
   - Enqueue la tarea en `FileDownloader`

6. **Monitoreo de Progreso**
   - Callback `taskProgressCallback` emite actualizaciones de progreso
   - Callback `taskStatusCallback` maneja cambios de estado:
     - `complete`: Actualiza estado a `completed`, registra tamaño de archivo y fecha
     - `failed`: Actualiza estado a `failed`
     - `canceled`: Actualiza estado a `canceled`
     - `paused`: Actualiza estado a `paused`

### 4.2 Estados de Descarga
- `pending`: Pendiente de iniciar
- `downloading`: En proceso de descarga
- `paused`: Pausado por usuario
- `completed`: Descarga finalizada exitosamente
- `failed`: Error en descarga
- `canceled`: Cancelado por usuario

### 4.3 Controles de Usuario
- **Pausar/Reanudar**: Disponible durante descarga
- **Cancelar**: Cancela descarga y elimina archivo parcial
- **Eliminar**: Elimina video descargado y registro en Hive

## 5. Ruta Privada en el Dispositivo

### 5.1 Ubicación
```
{ApplicationDocumentsDirectory}/videos/{courseId}_{videoId}.mp4
```

### 5.2 Características
- **Privacidad**: Directorio privado de la aplicación (no accesible por otras apps)
- **Persistencia**: Los archivos persisten entre cierres de app
- **Seguridad**: Solo la aplicación puede acceder a estos archivos
- **Cross-platform**: Funciona en iOS, Android, y otras plataformas soportadas

### 5.3 Ejemplos por Plataforma
- **Android**: `/data/data/{package}/app_flutter/videos/`
- **iOS**: `{AppContainer}/Documents/videos/`
- **Windows**: `%APPDATA%\{package}\videos\`

## 6. Almacenamiento en Hive

### 6.1 Estructura de Datos

**Modelo**: `DownloadedVideoHive` (typeId: 6)

```dart
@HiveType(typeId: 6)
class DownloadedVideoHive extends HiveObject {
  @HiveField(0)  String videoId;           // ID del video de YouTube
  @HiveField(1)  String courseId;          // ID del curso
  @HiveField(2)  String localPath;         // Ruta completa del archivo local
  @HiveField(3)  String downloadStatus;    // Estado de descarga
  @HiveField(4)  DateTime downloadedAt;     // Fecha de descarga
  @HiveField(5)  int fileSize;             // Tamaño en bytes
  @HiveField(6)  int watchedSeconds;       // Segundos visualizados
  @HiveField(7)  int totalSeconds;         // Duración total en segundos
  @HiveField(8)  bool pendingSync;         // Flag de sincronización pendiente
}
```

### 6.2 Caja Hive
- **Nombre**: `downloadedVideos`
- **Tipo**: `Box<DownloadedVideoHive>`
- **Key**: `videoId` (único por video)
- **Persistencia**: Automática en almacenamiento local

### 6.3 Operaciones Principales

**Guardar/Actualizar**:
```dart
await box.put(videoId, entity);
await entity.save(); // Para actualizaciones
```

**Recuperar**:
```dart
final item = box.get(videoId);
```

**Eliminar**:
```dart
await box.delete(videoId);
```

**Verificar disponibilidad**:
```dart
DownloadedVideoHive? getDownloadedVideo(String videoId) {
  final item = box.get(videoId);
  if (item != null && item.isCompleted && File(item.localPath).existsSync()) {
    return item;
  }
  return null;
}
```

### 6.4 Metadatos Almacenados

1. **Identificación**: `videoId`, `courseId`
2. **Ubicación**: `localPath` (ruta absoluta del archivo)
3. **Estado**: `downloadStatus`, `downloadedAt`
4. **Progreso**: `watchedSeconds`, `totalSeconds`
5. **Sincronización**: `pendingSync` (indica si hay cambios por sincronizar con servidor)

## 7. Política de Eliminación

### 7.1 Eliminación Manual
El usuario puede eliminar videos descargados a través del botón de descarga:
- Icono verde con check indica video descargado
- Menú popup con opción "Eliminar descarga"
- Elimina tanto el archivo físico como el registro en Hive

### 7.2 Proceso de Eliminación
```dart
Future<void> deleteLocalVideo(String videoId) async {
  final item = box.get(videoId);
  if (item != null) {
    // 1. Eliminar archivo físico
    final file = File(item.localPath);
    if (await file.exists()) {
      await file.delete();
    }
    // 2. Eliminar registro en Hive
    await box.delete(videoId);
  }
}
```

### 7.3 Cancelación de Descarga
Si se cancela una descarga en progreso:
- Se cancela la tarea en `FileDownloader`
- Se elimina el archivo parcial (si existe)
- Se elimina el registro en Hive

### 7.4 Limpieza Automática
Actualmente **NO** hay política de eliminación automática basada en:
- Tiempo desde descarga
- Última visualización
- Espacio de almacenamiento

**Nota**: Se recomienda implementar una política de limpieza en el futuro para gestionar el espacio de almacenamiento.

## 8. Reproducción Offline Sin Red

### 8.1 Detección de Video Offline

En `VideoTrackingWidget`:
```dart
void _checkVideoSource() {
  final downloaded = VideoDownloadService().getDownloadedVideo(widget.videoId);
  if (downloaded != null && downloaded.isCompleted) {
    _downloadedVideo = downloaded;
    _isOfflineVideo = true;
  } else {
    _isOfflineVideo = false;
    _initializePlayer(); // YouTube player
  }
}
```

### 8.2 Reproductor Local vs Online

**Si video está descargado** (`_isOfflineVideo == true`):
- Usa `LocalVideoPlayerWidget`
- Carga archivo desde ruta local: `VideoPlayerController.file(File(filePath))`
- No requiere conexión a internet
- Mantiene tracking de progreso local

**Si video NO está descargado**:
- Usa `YoutubePlayerController`
- Requiere conexión a internet
- Streaming desde YouTube

### 8.3 Reproducción Tras Cierre/Reapertura

**Persistencia de Datos**:
1. **Archivo de video**: Permanece en directorio privado
2. **Metadatos Hive**: Persisten automáticamente
3. **Progreso visualizado**: Guardado en `watchedSeconds`

**Flujo de Reapertura**:
1. App inicializa `VideoDownloadService`
2. Abre caja Hive `downloadedVideos`
3. `getDownloadedVideo(videoId)` verifica:
   - Registro existe en Hive
   - Estado es `completed`
   - Archivo físico existe en ruta
4. Si todas las condiciones se cumplen → Reproduce offline

**Reanudación de Posición**:
```dart
// Recupera progreso guardado
final state = ref.read(videoTrackingProvider);
if (state.resumePosition > Duration.zero) {
  _pendingSeekPosition = state.resumePosition;
}

// Seek cuando reproductor está listo
if (_pendingSeekPosition != null) {
  await _controller.seekTo(_pendingSeekPosition!);
}
```

### 8.4 Sincronización de Progreso Offline

**Durante reproducción offline**:
```dart
VideoDownloadService().updateWatchedProgress(
  videoId: widget.videoId,
  watchedSeconds: position.inSeconds,
  totalSeconds: widget.totalDurationMs ~/ 1000,
  pendingSync: true, // Marca para sincronización
);
```

**Al restaurar conexión**:
- `OfflineSyncService` detecta conexión restaurada
- Procesa cola de sincronización
- Envía progreso acumulado al servidor
- Reconcilia conflictos entre datos locales y remotos

### 8.5 Prueba de Reproducción Offline

**Pasos para verificar**:
1. Descargar un video con conexión activa
2. Cerrar completamente la aplicación
3. Activar modo avión o desconectar red
4. Abrir la aplicación
5. Navegar a la lección con el video descargado
6. Verificar que:
   - El reproductor local se inicializa (no YouTube)
   - El video reproduce sin errores
   - El progreso se actualiza localmente
   - Los controles de reproducción funcionan

**Indicadores Visuales**:
- Icono verde con check en botón de descarga
- Tamaño del archivo mostrado en MB
- Reproductor nativo (no iframe de YouTube)

## 9. Consideraciones de Seguridad y Cumplimiento

### 9.1 Términos de Servicio de YouTube
- El sistema extrae URLs de streaming directas para descarga
- Los videos se almacenan localmente para uso offline

### 9.2 Gestión de Derechos
- Los videos deben ser propiedad del usuario o tener licencia apropiada
- Considerar implementar DRM si es necesario
- Los archivos descargados no deben ser compartidos fuera de la aplicación

### 9.3 Privacidad de Datos
- Los metadatos de visualización se almacenan localmente
- La sincronización con el servidor requiere autenticación
- Los archivos de video están en directorio privado de la app

## 10. Archivos Relacionados

### Código Fuente
- `lib/core/services/video_download_service.dart` - Servicio principal de descarga
- `lib/data/models/downloaded_video_hive.dart` - Modelo de datos Hive
- `lib/presentation/widgets/video_download_button.dart` - UI de descarga
- `lib/presentation/widgets/local_video_player_widget.dart` - Reproductor local
- `lib/presentation/widgets/video_tracking_widget.dart` - Widget de tracking con detección offline
- `lib/core/services/offline_sync_service.dart` - Sincronización offline

### Configuración
- `pubspec.yaml` - Dependencias del proyecto

## 11. Mejoras Futuras Sugeridas

1. **Política de Limpieza Automática**: Eliminar videos no visualizados en X días
2. **Gestión de Espacio**: Alertas cuando el almacenamiento está lleno
3. **Calidad Selectiva**: Permitir al usuario elegir calidad de descarga
4. **Descarga en Lote**: Descargar múltiples videos de un curso
5. **Compresión**: Opcionalmente comprimir videos para ahorrar espacio
6. **Cifrado**: Cifrar videos descargados para mayor seguridad
7. **Métricas**: Tracking de uso de descargas para análisis

---