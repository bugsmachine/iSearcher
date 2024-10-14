// lib/models/video_file.dart
class VideoFile {
  final String name;
  final String path;
  final int size; // in bytes
  final DateTime lastModified;

  VideoFile({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
  });
}