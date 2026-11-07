// lib/domain/entities/media_resource.dart

class MediaResource {
  final String id;
  final String url;
  final String filename;
  final String mimeType; // e.g., video/mp4, image/png, application/pdf
  final int sizeBytes;
  final Duration? duration; // for audio/video
  final Map<String, dynamic>? metadata; // thumbnails, width/height, etc.

  const MediaResource({
    required this.id,
    required this.url,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    this.duration,
    this.metadata,
  });

  factory MediaResource.fromMap(Map<String, dynamic> map) {
    final durationSeconds = map['durationSeconds'];
    final durationMs = map['durationMs'];

    return MediaResource(
      id: map['id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      filename: map['filename'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      duration:
          durationSeconds != null
              ? Duration(seconds: (durationSeconds as num).toInt())
              : durationMs != null
              ? Duration(milliseconds: (durationMs as num).toInt())
              : null,
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'durationSeconds': duration?.inSeconds,
      'metadata': metadata,
    };
  }
}

class MediaUploadRequest {
  final String filename;
  final String mimeType;
  final List<int> bytes;

  const MediaUploadRequest({
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });
}
