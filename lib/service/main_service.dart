import 'dart:io';
import '../models/video_file.dart'; // Import the VideoFile model


Future<void> appConfigInit(String path) async {
  // Create a folder in the user's film_folder directory called 'config'
  final Directory configDir = Directory('$path/config');
  if (!configDir.existsSync()) {
    configDir.createSync();
  }

  final Directory recordedFilmsDir = Directory('$path/recorded_films');
  if (!recordedFilmsDir.existsSync()) {
    recordedFilmsDir.createSync();
  }

  // Create a file in the 'config' directory called 'app_config.txt'
  final File configFile = File('$path/config/app_config.txt');
  if (!configFile.existsSync()) {
    configFile.createSync();
  }

  // Write the default configuration to the file
  // get the current time and write it to the file
  DateTime now = DateTime.now();
  configFile.writeAsStringSync('''
  {
    "last_db_modified": "${now.toIso8601String()}",
    "language": "en"
  }
  ''');

  // create a text file for each table in the database
  final File categoriesFile = File('$path/config/categories.txt');
  if (!categoriesFile.existsSync()) {
    categoriesFile.createSync();
  }

  final File keywordsFile = File('$path/config/keywords.txt');
  if (!keywordsFile.existsSync()) {
    keywordsFile.createSync();
  }

  final File moviesFile = File('$path/config/movies.txt');
  if (!moviesFile.existsSync()) {
    moviesFile.createSync();
  }

  final File movieKeywordsFile = File('$path/config/movie_keywords.txt');
  if (!movieKeywordsFile.existsSync()) {
    movieKeywordsFile.createSync();
  }

  final File userDefaultFile = File('$path/config/user_default.txt');
  if (!userDefaultFile.existsSync()) {
    userDefaultFile.createSync();
  }

  final File configTableFile = File('$path/config/config.txt');
  if (!configTableFile.existsSync()) {
    configTableFile.createSync();
  }

}

// write data to the txt file
Future<void> writeDataToFile(String path, String fileName, String data) async {
  final File file = File('$path/config/$fileName');
  if (!file.existsSync()) {
    file.createSync();
  }

  // Check if the file is empty
  if (file.lengthSync() == 0) {
    file.writeAsStringSync(data);
  } else {
    file.writeAsStringSync(data, mode: FileMode.append);
  }
}

// Read all the video files in the film_folder directory recursively and return a list of VideoFile objects
Future<List<VideoFile>> readVideoFiles(String path) async {
  final Directory filmsDir = Directory(path);
  if (!filmsDir.existsSync()) {
    print("Directory does not exist: $path");
    return []; // Return an empty list if the directory does not exist
  }

  const List<String> videoExtensions = [
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.flv',
    '.wmv',
    '.webm',
    '.mpeg',
    '.mpg'
  ];

  List<VideoFile> videoFiles = [];
  await _getVideoFilesRecursively(filmsDir, videoFiles, videoExtensions);

  // print the video files
  // for (var videoFile in videoFiles) {
  //   print('Name: ${videoFile.name}, Path: ${videoFile.path}, Size: ${videoFile.size}, Last Modified: ${videoFile.lastModified}');
  // }

  return videoFiles; // Return the list of video files
}

Map<String, String?> extractVideoDetails(String filename) {
  // Define regex patterns
  final yearPattern = RegExp(r"\b(19|20)\d{2}\b");
  final resolutionPattern = RegExp(r"\b(2160p|1080p|720p|4k)\b");
  final sourcePattern = RegExp(r"(BluRay|WEB-DL|REMUX|HDRip|UHD|WEBRip)", caseSensitive: false);
  final audioPattern = RegExp(r"(Atmos|DTS-HD|TrueHD|DDP|DD|7\.1|5\.1)", caseSensitive: false);

  // Extract parts using regex
  final yearMatch = yearPattern.firstMatch(filename);
  final resolutionMatch = resolutionPattern.firstMatch(filename);
  final sourceMatches = sourcePattern.allMatches(filename);
  final audioMatches = audioPattern.allMatches(filename);

  // Process title
  String? title = cleanTitle(filename);

  // Convert sources to a readable format
  List<String> sources = sourceMatches.map((match) => match.group(0)!.toLowerCase()).toList();
  if (sources.contains('remux')) {
    sources.remove('remux');
    sources.add('Remux');
  }
  String sourceFormatted = sources.map((source) => capitalizeFirstLetter(source)).join(', ');

  // Extract primary audio formats (just check if Atmos exists)
  String audioFormats = audioMatches.any((match) => match.group(0)!.toLowerCase() == 'atmos')
      ? 'Atmos'
      : 'Not Atmos';

  // Prepare the parsed data
  return {
    'title': title,
    'year': yearMatch != null ? yearMatch.group(0) : null,
    'resolution': resolutionMatch != null ? resolutionMatch.group(0) : null,
    'source': sourceFormatted,
    'audio': audioFormats,
  };
}

String? cleanTitle(String filename) {
  // Remove file extension
  String nameWithoutExtension = filename.replaceAll(RegExp(r'\.[^\.]+$'), '');

  // Remove common patterns that are not part of the title
  final removePattern = RegExp(
      r'\b(19|20)\d{2}\b|'  // Year
      r'\b(2160p|1080p|720p|4k)\b|'  // Resolution
      r'\b(BluRay|WEB-DL|REMUX|HDRip|UHD|WEBRip)\b|'  // Source
      r'\b(Atmos|DTS-HD|TrueHD|DDP\d?|DD\d?|[57]\.1)\b|'  // Audio
      r'\b(x264|x265|HEVC|10bit|HDR|DoVi|SDR)\b|'  // Encoding
      r'\b(PROPER|REPACK|IMAX|Extended|Edition|Cut)\b|'  // Other common terms
      r'[-\.]v\d|'  // Version numbers like .v2 or -v3
      r'\b[a-zA-Z0-9]{2,8}\b$|'  // Release group at the end
      r'\bMA\b|'  // MA (possibly for Master Audio)
      r'\b\d+Audio\b|'  // Audio channel count (e.g., 2Audio)
      r'\bTrueHD\d+\s*\d*\b',  // TrueHD followed by numbers
      caseSensitive: false
  );

  String cleanedTitle = nameWithoutExtension.replaceAll(removePattern, ' ');

  // Replace separators with spaces
  cleanedTitle = cleanedTitle.replaceAll(RegExp(r'[\.\_\-]+'), ' ');

  // Remove multiple spaces and trim
  cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Capitalize the first letter of each word
  cleanedTitle = cleanedTitle.split(' ').map((word) => capitalizeFirstLetter(word)).join(' ');

  return cleanedTitle;
}

String capitalizeFirstLetter(String word) {
  return word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word;
}



Future<void> _getVideoFilesRecursively(Directory dir, List<VideoFile> videoFiles, List<String> videoExtensions) async {
  try {
    List<FileSystemEntity> entities = dir.listSync();

    for (final FileSystemEntity entity in entities) {
      if (entity is File) {
        if (videoExtensions.any((extension) => entity.path.toLowerCase().endsWith(extension))) {
          final fileStat = await entity.stat();
          // add movie which have size > 1gb
          if (fileStat.size > 1) {
            videoFiles.add(VideoFile(
              name: entity.uri.pathSegments.last,
              path: entity.path,
              size: fileStat.size,
              lastModified: fileStat.modified,
            ));
          }
        }
      } else if (entity is Directory) {
        if (entity.path.split('/').last != 'recorded_films') {
          await _getVideoFilesRecursively(entity, videoFiles, videoExtensions);
        }
      }
    }
  } catch (e) {
    print("Error reading directory ${dir.path}: $e");
  }
}