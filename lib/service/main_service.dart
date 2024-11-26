import 'dart:io';
import '../models/video_file.dart'; // Import the VideoFile model
import '../repository/db.dart'; // Import the database helper functions


Future<void> appConfigInit(String path) async {
  // Create a folder in the user's film_folder directory called 'config'
  final Directory configDir = Directory('$path/config');
  if (!configDir.existsSync()) {
    configDir.createSync();

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

    await updateConfig("last_write_config_time", now.toIso8601String());
  }else{
    print("config folder already exists");
  }
}

// sync the database with the txt files
Future<void> syncDatabase(String path) async {
  String? lastAPPWrite = await getConfig("last_write_config_time");
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
  await updateConfig("last_write_config_time", DateTime.now().toIso8601String());
}

// Read all the video files in the film_folder directory recursively and return a list of VideoFile objects
Future<List<VideoFile>> readVideoFiles(String path) async {
  final Directory filmsDir = Directory(path);
  if (!filmsDir.existsSync()) {
    print("No such file or directory");

    return[VideoFile(name: "F01", path: "No such file or directory", size: -9999, lastModified: DateTime.now())];
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

  if (videoFiles.isEmpty) {
    print("No video files found in the film_folder directory");
    return[VideoFile(name: "F02", path: "No video files found in the directory", size: -9999, lastModified: DateTime.now())];
  }else{
    print("video files number: ${videoFiles.length}");
  }

  return videoFiles; // Return the list of video files
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
    // if exception is folder not found, clean the videoFiles add the exception code f01 to the list

  }
}


Future<void> addFileToDB() async {

}