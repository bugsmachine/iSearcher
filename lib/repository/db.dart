import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../service/main_service.dart';

late Database db;

Future<void> iniDB() async {
  // Get the user's home directory
  Directory homeDir = Directory(Platform.environment['HOME']!);

  // Specify the path to the shared folder
  String sharedFolderPath = join(homeDir.path, 'shared_folder');

  String newDBFolderPath = join(sharedFolderPath, 'newDB');

  // Specify the replacement database file path
  String replacementDbPath = join(sharedFolderPath, 'replacement_movies_database.db');

  // Check if the replacement database file exists
  if (await File(replacementDbPath).exists()) {
    print("Replacement database file found. Using it to initialize the database.");
    await initDatabaseFromDBFile(replacementDbPath);
  } else {
    print("No replacement database file found. Initializing default database.");
    await initDatabase();
  }
}

Future<void> initDatabaseFromDBFile(String dbFilePath) async {
  print("Initializing database from specified file: $dbFilePath");

  // Open the specified database file without altering schema
  db = await openDatabase(
    dbFilePath,
    readOnly: false, // Set to true if you want to avoid accidental data modifications
    onOpen: (db) {
      print("Database successfully opened from $dbFilePath");
    },
  );
}


Future<void> initDatabase() async {
  print("initDatabase");

  // Get the user's home directory
  Directory homeDir = Directory(Platform.environment['HOME']!);

  // Specify the path to the shared folder
  String sharedFolderPath = join(homeDir.path, 'shared_folder');

  // Create the shared folder if it doesn't exist
  await Directory(sharedFolderPath).create(recursive: true);

  // Specify the path to the database file
  String dbPath = join(sharedFolderPath, 'movies_database.db');
  String replacementDbPath = join(sharedFolderPath, 'replacement_movies_database.db');

  print("dbPath: $dbPath");

  // Check if a replacement database file exists
  if (await File(replacementDbPath).exists()) {
    print("Replacement database found. Replacing current database...");
    await File(replacementDbPath).copy(dbPath);
    await File(replacementDbPath).delete(); // Optionally delete the replacement file after copying
  }

  print("dbPath: $dbPath");
  db = await openDatabase(
    dbPath,
    version: 29, // Increment the version number
    onCreate: (db, version) {
      print("onCreate");
      return db.transaction((txn) async {
        // Create Movies table
        await txn.execute('''
          CREATE TABLE Movies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      });
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      print("onUpgrade");
      await db.transaction((txn) async {
        // Drop existing tables
        await txn.execute('DROP TABLE IF EXISTS Files');
        await txn.execute('DROP TABLE IF EXISTS Keywords');
        await txn.execute('DROP TABLE IF EXISTS FileKeywords');
        await txn.execute('DROP TABLE IF EXISTS Groups');
        await txn.execute('DROP TABLE IF EXISTS Genres');
        await txn.execute('DROP TABLE IF EXISTS GenresAndFiles');
        await txn.execute('DROP TABLE IF EXISTS UserDefault');
        await txn.execute('DROP TABLE IF EXISTS Config');
        await txn.execute('DROP TABLE IF EXISTS GenresIntl');
        await txn.execute('DROP TABLE IF EXISTS MovieInfo');
        await txn.execute('DROP TABLE IF EXISTS Cast');
        await txn.execute('DROP TABLE IF EXISTS CastAndMovie');

        // Recreate tables with new schema
        await txn.execute('''
  CREATE TABLE Files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    group_id INTEGER NOT NULL,
    FOREIGN KEY (group_id) REFERENCES Groups(id)
  )
''');

        await txn.execute('''
  CREATE TABLE MovieInfo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER NOT NULL,
    overview TEXT NOT NULL,
    vote TEXT NOT NULL,
    poster TEXT NOT NULL,
    label TEXT NOT NULL,
    FOREIGN KEY (file_id) REFERENCES Files(id)
  )
''');

        await txn.execute('''
  CREATE TABLE GenresIntl (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    en TEXT NOT NULL,
    zh TEXT NOT NULL,
    zh_TW TEXT NOT NULL
  )
''');

        await txn.execute('''
  CREATE TABLE Genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    group_id INTEGER NOT NULL,
    FOREIGN KEY (group_id) REFERENCES Groups(id)
  )
''');

        await txn.execute('''
  CREATE TABLE GenresAndFiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    FOREIGN KEY (file_id) REFERENCES Files(id),
    FOREIGN KEY (genre_id) REFERENCES Genres(id)
  )
''');

        await txn.execute('''
          CREATE TABLE Groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            password TEXT,
            icon TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE Keywords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            keyword TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE UserDefault (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bookMarks TEXT NOT NULL,
            films_folder TEXT NOT NULL,
            last_db_modified TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE Config (
            id TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE FileKeywords (
            file_id INTEGER,
            keyword_id INTEGER,
            FOREIGN KEY(file_id) REFERENCES Files(id),
            FOREIGN KEY(keyword_id) REFERENCES Keywords(id),
            PRIMARY KEY (file_id, keyword_id)
          )
        ''');

        await txn.execute('''
          CREATE TABLE Cast (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            avatar TEXT NOT NULL,
            tmdb_id TEXT NOT NULL
          )
        ''');

        await txn.execute('''
          CREATE TABLE CastAndMovie (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cast_id INTEGER,
            file_id INTEGER,
            character_name TEXT NOT NULL
         
          )
        ''');

        // add groups
        await txn.execute('''INSERT INTO Groups(name, password, icon) VALUES ('Movies', '',"Icons.video_library_outlined");''');
        await txn.execute('''INSERT INTO Groups(name, password, icon) VALUES ('TV Shows', '',"Icons.video_library_outlined");''');
        await txn.execute('''INSERT INTO Groups(name, password, icon) VALUES ('Photos', '',"Icons.video_library_outlined");''');

        // add some example genres
        // await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('Action', 1);''');
        // await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('Comedy', 1);''');
        // await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('Drama', 1);''');

        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('aaaa', 2);''');
        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('bbbb', 2);''');
        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('cccc', 2);''');

        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('1234', 3);''');
        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('2345y', 3);''');
        await txn.execute('''INSERT INTO Genres(name, group_id) VALUES ('5678', 3);''');

        // Add default rows
        await txn.execute('''INSERT INTO UserDefault(bookMarks, films_folder, last_db_modified) VALUES ('null1', 'null1', 'null1');''');
        // default config
        await txn.execute('''INSERT INTO Config(id, value) VALUES ('library_permission', 'no');''');

        await txn.execute('''INSERT INTO Config(id, value) VALUES ('search_engine', 'https://www.google.com');''');
        await txn.execute('''INSERT INTO Config(id, value) VALUES ('platform', 'null2');''');
        await txn.execute('''INSERT INTO Config(id, value) VALUES ('last_write_config_time', 'en');''');

        // Indexes for efficient searching
        await txn.execute('CREATE INDEX idx_keyword_id ON FileKeywords(keyword_id)');
        await txn.execute('CREATE INDEX idx_movie_id ON FileKeywords(File_id)');
      });
    },
  );
}

Future<bool> insertFile(String path, String name, String type, int group) async{
  print("insertFile");
  var result = await db.insert('Files', {'path': path, 'name': name, 'type': type, 'group_id': group});
  return result > 0;
}

Future<int> getFileIDByName(String name) async{
  print("getFileIDByName");
  List<Map<String, dynamic>> files = await db.query('Files', where: 'name = ?', whereArgs: [name]);
  if (files.isEmpty) {
    return -1;
  }
  return files[0]['id'];
}

Future<int> getGroupID(String name) async{
  print("getGroupID");
  List<Map<String, dynamic>> groups = await db.query('Groups', where: 'name = ?', whereArgs: [name]);
  if (groups.isEmpty) {
    return -1;
  }
  return groups[0]['id'];
}

Future<bool> insertGenres(String name, int group) async{
  print("insertGenres");
  var result = await db.insert('Genres', {'name': name, 'group_id': group});
  return result > 0;
}

Future<bool> isGenreExist(String name, int group) async{
  print("isGenresExist");
  List<Map<String, dynamic>> genres = await db.query('Genres', where: 'name = ? AND group_id = ?', whereArgs: [name, group]);
  return genres.isNotEmpty;
}

Future<bool> insertMovieInfo(int fileId, String overview, String vote, String poster, String label) async{
  print("insertMovieInfo");
  var result = await db.insert('MovieInfo', {'file_id': fileId, 'overview': overview, 'vote': vote, 'poster': poster, 'label': label});
  return result > 0;
}

Future<bool> insertKeywords(String name) async{
  print("insertTags");
  var result = await db.insert('Keywords', {'keyword': name});
  return result > 0;
}

Future<int> getKeywordIDByName(String keyword) async{
  print("getKeywordIDByName");
  List<Map<String, dynamic>> keywords = await db.query('Keywords', where: 'keyword = ?', whereArgs: [keyword]);
  if (keywords.isEmpty) {
    return -1;
  }
  return keywords[0]['id'];
}

Future<bool> insertFilesAndTags(int fileId, int keywordId) async{
  print("insertFilesAndTags");
  var result = await db.insert('FileKeywords', {'file_id': fileId, 'keyword_id': keywordId});
  return result > 0;
}

Future<int> getGenreIDByNameAndGroup(String name, int groupID) async{
  print("getGenreIDByNameAndGroup");
  List<Map<String, dynamic>> genres = await db.query('Genres', where: 'name = ? AND group_id = ?', whereArgs: [name, groupID]);
  if (genres.isEmpty) {
    return -1;
  }
  return genres[0]['id'];
}

Future<bool> insertGenresAndFiles(int fileId, int genreId) async{
  print("insertGenresAndFiles");
  var result = await db.insert('GenresAndFiles', {'file_id': fileId, 'genre_id': genreId});
  return result > 0;
}


Future<bool> insertCast(String name, String avatar, String ID) async{
  print("insertCast");
  var result = await db.insert('Cast', {'name': name, 'avatar': avatar, 'tmdb_id': ID});
  return result > 0;
}

Future<int> getCastIDByTMDBID(String tmdbID) async{
  print("getCastIDByTMDBID");
  List<Map<String, dynamic>> cast = await db.query('Cast', where: 'tmdb_id = ?', whereArgs: [tmdbID]);
  if (cast.isEmpty) {
    return -1;
  }
  return cast[0]['id'];
}

Future<bool> insertCastAndMovie(int castId, int fileId, String characterName) async{
  print("insertCastAndMovie");
  var result = await db.insert('CastAndMovie', {'cast_id': castId, 'file_id': fileId, 'character_name': characterName});
  return result > 0;
}




Future<void> insertAllGenres() async {
  try {
    // Check if the table is empty
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM GenresIntl'));
    if (count == 0) {
      // List of genres to insert
      print("insertAllGenres111112121212121212121212");
      final genres = [
        {'en': 'Action', 'zh': '动作', 'zh_TW': '動作'},
        {'en': 'Adventure', 'zh': '冒险', 'zh_TW': '冒險'},
        {'en': 'Animation', 'zh': '动画', 'zh_TW': '動畫'},
        {'en': 'Comedy', 'zh': '喜剧', 'zh_TW': '喜劇'},
        {'en': 'Crime', 'zh': '犯罪', 'zh_TW': '犯罪'},
        {'en': 'Documentary', 'zh': '纪录', 'zh_TW': '紀錄'},
        {'en': 'Drama', 'zh': '剧情', 'zh_TW': '劇情'},
        {'en': 'Family', 'zh': '家庭', 'zh_TW': '家庭'},
        {'en': 'Fantasy', 'zh': '奇幻', 'zh_TW': '奇幻'},
        {'en': 'History', 'zh': '历史', 'zh_TW': '歷史'},
        {'en': 'Horror', 'zh': '恐怖', 'zh_TW': '恐怖'},
        {'en': 'Music', 'zh': '音乐', 'zh_TW': '音樂'},
        {'en': 'Mystery', 'zh': '悬疑', 'zh_TW': '懸疑'},
        {'en': 'Romance', 'zh': '爱情', 'zh_TW': '愛情'},
        {'en': 'Science Fiction', 'zh': '科幻', 'zh_TW': '科幻'},
        {'en': 'TV Movie', 'zh': '电视电影', 'zh_TW': '電視電影'},
        {'en': 'Thriller', 'zh': '惊悚', 'zh_TW': '驚悚'},
        {'en': 'War', 'zh': '战争', 'zh_TW': '戰爭'},
        {'en': 'Western', 'zh': '西部', 'zh_TW': '西部'},
      ];

      // Start a batch for inserting multiple records
      final batch = db.batch();
      for (var genre in genres) {
        batch.insert(
          'GenresIntl',
          genre,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Execute the batch
      await batch.commit(noResult: true);

      print('All genres inserted successfully.');
    } else {
      print('GenresIntl table is not empty. Skipping insertion.');
    }
  } catch (e) {
    print('Error inserting genres: $e');
  }
}


// get the genre of a group
Future<List<Map<String, dynamic>>> getGenres(int groupId) async {
  print("getGenres");
  List<Map<String, dynamic>> genres = await db.query('Genres', where: 'group_id = ?', whereArgs: [groupId]);

  return genres;
}


Future<List<Map<String, dynamic>>> getGroups() async {
  print("getGroups");
  List<Map<String, dynamic>> groups = await db.query('Groups');

  return groups;
}


// update the config
Future<void> updateConfig(String key, String value) async {
  print("updateConfig of key:  $key value: $value");
  await db.update('Config', {'value': value}, where: 'id = ?', whereArgs: [key]);

}

// insert a new config
Future<void> insertConfig(String key, String value) async {
  print("insertConfig of key:  $key value: $value");
  await db.insert('Config', {'id': key, 'value': value});
}

Future<String?> getConfig(String key) async {
  print("getConfig of key:  " + key);
  List<Map<String, dynamic>> config = await db.query('Config', where: 'id = ?', whereArgs: [key]);
  if (config.isEmpty) {
    return null;
  }
  return config[0]['value'];
}

Future<void> printAll() async{
  print("printAll");
  await printAllMovies();
  await printAllKeywords();
  await printAllMovieKeywords();
}

Future<List<String>> getCategories() async {
  print("getCategories");
  List<Map<String, dynamic>> categories = await db.query('Categories');
  List<String> categoryNames = [];
  for (var category in categories) {
    categoryNames.add(category['name']);
  }
  return categoryNames;
}

Future<void> insertCategory(String name) async {
  print("insertCategory: $name");
  await db.insert('Categories', {'name': name});
}

// delete a category by name
Future<void> deleteCategory(String name) async {
  print("deleteCategory: $name");
  await db.delete('Categories', where: 'name = ?', whereArgs: [name]);
}

// Function to print all data in the Movies table
Future<void> printAllMovies() async {
  List<Map<String, dynamic>> movies = await db.query('Movies');
  for (var movie in movies) {
    print('Movie ID: ${movie['id']}, Path: ${movie['path']}');
  }
}

// Function to print all data in the MovieKeywords table
Future<void> printAllMovieKeywords() async {
  List<Map<String, dynamic>> movieKeywords = await db.query('MovieKeywords');
  for (var movieKeyword in movieKeywords) {
    print('Movie ID: ${movieKeyword['movie_id']}, Keyword ID: ${movieKeyword['keyword_id']}');
  }
}

// Function to print all data in the Keywords table
Future<void> printAllKeywords() async {
  List<Map<String, dynamic>> keywords = await db.query('Keywords');
  for (var keyword in keywords) {
    print('Keyword ID: ${keyword['id']}, Keyword: ${keyword['keyword']}');
  }
}

// Load all the data from user_default table, ordered by the actual time, the newest first
Future<List<Map<String, dynamic>>> loadAllUserDefaultDESCInTime() async {
  print("loadAllUserDefault");
  return await db.query('UserDefault', orderBy: 'datetime(last_db_modified) DESC');
}

// get the film_folder of row 1 from table UserDefault, if not exist return null
Future<String?> getUserDefaultOfLine1(String key) async {
  print("getUserDefaultOfLine1");

  List<Map<String, dynamic>> userDefaults = await db.query('UserDefault');
  for (var userDefault in userDefaults) {
    if (userDefault['id'] == 1) {
      return userDefault[key];
    }
  }
  return null;
}

// set the film_folder of row 1 from table UserDefault
Future<void> setUserDefaultOfLine1(String bookMark, String filmFolder) async {
  print("setUserDefaultOfLine1");
  await db.update('UserDefault', {'bookMarks': bookMark, 'films_folder': filmFolder, 'last_db_modified': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [1]);
  String writeFilePath = '$filmFolder/config';
  String data = '''
  {
    "bookMarks": "$bookMark",
    "films_folder": "$filmFolder",
    "last_db_modified": "${DateTime.now().toIso8601String()}"
  },
  ''';
  writeDataToFile(filmFolder, "user_default.txt", data);
}

// set the film_folder of row 1 from table UserDefault
Future<void> addNewUserDefault(String bookMark, String filmFolder) async {
  print("addNewUserDefault");
  await db.insert('UserDefault', {'bookMarks': bookMark, 'films_folder': filmFolder, 'last_db_modified': DateTime.now().toIso8601String()});
  //append the new data to the file
  String data = '''
  {
    "bookMarks": "$bookMark",
    "films_folder": "$filmFolder",
    "last_db_modified": "${DateTime.now().toIso8601String()}"
  },
  ''';
  writeDataToFile(filmFolder, "user_default.txt", data);
}


// Function to insert a movie and its associated keywords
Future<void> insertMovie(String path, List<String> keywords) async {

  print("insertMovie" + path);
  // Insert movie into Movies table
  int movieId = await db.insert('Movies', {'path': path});

  for (String keyword in keywords) {
    // Check if keyword already exists in Keywords table
    List<Map> existingKeywords = await db.query(
      'Keywords',
      where: 'keyword = ?',
      whereArgs: [keyword],
    );

    int keywordId;
    if (existingKeywords.isNotEmpty) {
      // Use the existing keyword ID
      keywordId = existingKeywords.first['id'];
    } else {
      // Insert new keyword and get its ID
      keywordId = await db.insert('Keywords', {'keyword': keyword});
    }

    // Insert movie and keyword relationship into MovieKeywords table
    await db.insert('MovieKeywords', {
      'movie_id': movieId,
      'keyword_id': keywordId,
    });
  }
}

// Function to search movies by keyword
Future<List<Map<String, dynamic>>> searchMoviesByKeyword(String keyword) async {
  print("searchMoviesByKeyword     " + keyword);
  return await db.rawQuery('''
    SELECT Movies.path
    FROM Movies
    JOIN MovieKeywords ON Movies.id = MovieKeywords.movie_id
    JOIN Keywords ON MovieKeywords.keyword_id = Keywords.id
    WHERE Keywords.keyword = ?
  ''', [keyword]);
}


