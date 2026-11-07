import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';

void main() {
  group('MediaResource Tests', () {
    test('MediaResource creates correctly with all fields', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
        duration: const Duration(minutes: 5, seconds: 30),
        metadata: {'width': 1920, 'height': 1080},
      );

      expect(media.id, 'media_1');
      expect(media.url, 'https://example.com/video.mp4');
      expect(media.filename, 'video.mp4');
      expect(media.mimeType, 'video/mp4');
      expect(media.sizeBytes, 1024000);
      expect(media.duration, const Duration(minutes: 5, seconds: 30));
      expect(media.metadata, {'width': 1920, 'height': 1080});
    });

    test('MediaResource creates with optional fields null', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/image.png',
        filename: 'image.png',
        mimeType: 'image/png',
        sizeBytes: 512000,
      );

      expect(media.duration, null);
      expect(media.metadata, null);
    });

    test('MediaResource with different mime types', () {
      final video = MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
      );

      final image = MediaResource(
        id: 'media_2',
        url: 'https://example.com/image.jpg',
        filename: 'image.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 512000,
      );

      final pdf = MediaResource(
        id: 'media_3',
        url: 'https://example.com/document.pdf',
        filename: 'document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048000,
      );

      expect(video.mimeType, 'video/mp4');
      expect(image.mimeType, 'image/jpeg');
      expect(pdf.mimeType, 'application/pdf');
    });

    test('MediaResource with zero size', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/empty.txt',
        filename: 'empty.txt',
        mimeType: 'text/plain',
        sizeBytes: 0,
      );

      expect(media.sizeBytes, 0);
    });

    test('MediaResource with large size', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/large.mp4',
        filename: 'large.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1073741824, // 1GB
      );

      expect(media.sizeBytes, 1073741824);
    });

    test('MediaResource with duration', () {
      final short = MediaResource(
        id: 'media_1',
        url: 'https://example.com/short.mp4',
        filename: 'short.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
        duration: const Duration(seconds: 30),
      );

      final long = MediaResource(
        id: 'media_2',
        url: 'https://example.com/long.mp4',
        filename: 'long.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 10240000,
        duration: const Duration(hours: 2, minutes: 30),
      );

      expect(short.duration, const Duration(seconds: 30));
      expect(long.duration, const Duration(hours: 2, minutes: 30));
    });

    test('MediaResource with metadata', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
        metadata: {'width': 1920, 'height': 1080, 'fps': 30, 'codec': 'h264'},
      );

      expect(media.metadata?['width'], 1920);
      expect(media.metadata?['height'], 1080);
      expect(media.metadata?['fps'], 30);
      expect(media.metadata?['codec'], 'h264');
    });

    test('MediaResource with empty metadata', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
        metadata: {},
      );

      expect(media.metadata, isEmpty);
    });
  });

  group('MediaUploadRequest Tests', () {
    test('MediaUploadRequest creates correctly', () {
      final request = MediaUploadRequest(
        filename: 'test.pdf',
        mimeType: 'application/pdf',
        bytes: [1, 2, 3, 4, 5],
      );

      expect(request.filename, 'test.pdf');
      expect(request.mimeType, 'application/pdf');
      expect(request.bytes, [1, 2, 3, 4, 5]);
    });

    test('MediaUploadRequest with empty bytes', () {
      final request = MediaUploadRequest(
        filename: 'empty.txt',
        mimeType: 'text/plain',
        bytes: [],
      );

      expect(request.bytes, isEmpty);
    });

    test('MediaUploadRequest with large bytes', () {
      final largeBytes = List.generate(10000, (index) => index % 256);
      final request = MediaUploadRequest(
        filename: 'large.bin',
        mimeType: 'application/octet-stream',
        bytes: largeBytes,
      );

      expect(request.bytes.length, 10000);
    });

    test('MediaUploadRequest with different mime types', () {
      final video = MediaUploadRequest(
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        bytes: [1, 2, 3],
      );

      final image = MediaUploadRequest(
        filename: 'image.png',
        mimeType: 'image/png',
        bytes: [4, 5, 6],
      );

      final audio = MediaUploadRequest(
        filename: 'audio.mp3',
        mimeType: 'audio/mpeg',
        bytes: [7, 8, 9],
      );

      expect(video.mimeType, 'video/mp4');
      expect(image.mimeType, 'image/png');
      expect(audio.mimeType, 'audio/mpeg');
    });

    test('MediaUploadRequest with special characters in filename', () {
      final request = MediaUploadRequest(
        filename: 'documento_ñáéíóú.pdf',
        mimeType: 'application/pdf',
        bytes: [1, 2, 3],
      );

      expect(request.filename, 'documento_ñáéíóú.pdf');
    });

    test('MediaUploadRequest with long filename', () {
      final longFilename = 'a' * 200 + '.pdf';
      final request = MediaUploadRequest(
        filename: longFilename,
        mimeType: 'application/pdf',
        bytes: [1, 2, 3],
      );

      expect(request.filename.length, 204);
    });

    test('MediaUploadRequest with binary data', () {
      final binaryData = [0, 255, 128, 64, 32];
      final request = MediaUploadRequest(
        filename: 'binary.bin',
        mimeType: 'application/octet-stream',
        bytes: binaryData,
      );

      expect(request.bytes[0], 0);
      expect(request.bytes[1], 255);
      expect(request.bytes[2], 128);
      expect(request.bytes[3], 64);
      expect(request.bytes[4], 32);
    });
  });
}
