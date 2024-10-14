import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../service/main_service.dart';

late Database db;

// Initialize the database
Future<void> initDatabase() async {
  print("initDatabase");
  db = await openDatabase(
    join(await getDatabasesPath(), 'movies_database.db'),
    version: 24, // Increment the version number
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

        // Create Keywords table
        await txn.execute('''
          CREATE TABLE Keywords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            keyword TEXT NOT NULL
          )
        ''');

        // Create MovieKeywords (junction table) to map movies and keywords
        await txn.execute('''
          CREATE TABLE MovieKeywords (
            movie_id INTEGER,
            keyword_id INTEGER,
            FOREIGN KEY(movie_id) REFERENCES Movies(id),
            FOREIGN KEY(keyword_id) REFERENCES Keywords(id),
            PRIMARY KEY (movie_id, keyword_id)
          )
        ''');

        // Indexes for efficient searching
        await txn.execute('CREATE INDEX idx_keyword_id ON MovieKeywords(keyword_id)');
        await txn.execute('CREATE INDEX idx_movie_id ON MovieKeywords(movie_id)');
      });
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      print("onUpgrade");
      await db.transaction((txn) async {
        // Drop existing tables
        await txn.execute('DROP TABLE IF EXISTS Movies');
        await txn.execute('DROP TABLE IF EXISTS Keywords');
        await txn.execute('DROP TABLE IF EXISTS MovieKeywords');
        await txn.execute('DROP TABLE IF EXISTS Categories');
        await txn.execute('DROP TABLE IF EXISTS UserDefault');
        await txn.execute('DROP TABLE IF EXISTS Config');

        // Recreate tables with new schema
        await txn.execute('''
      CREATE TABLE Movies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        category INTEGER,
        FOREIGN KEY (category) REFERENCES Categories(id)
      )
    ''');

        await txn.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
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
      CREATE TABLE MovieKeywords (
        movie_id INTEGER,
        keyword_id INTEGER,
        FOREIGN KEY(movie_id) REFERENCES Movies(id),
        FOREIGN KEY(keyword_id) REFERENCES Keywords(id),
        PRIMARY KEY (movie_id, keyword_id)
      )
    ''');

        // add a default row value in user default
        await txn.execute('''INSERT INTO UserDefault(bookMarks,films_folder, last_db_modified) VALUES ('null1','null1','null1');''');

        // add a default row value in config with ID "search_engine"
        await txn.execute('''INSERT INTO Config(id, value) VALUES ('search_engine', 'https://www.google.com');''');
        await txn.execute('''INSERT INTO Config(id, value) VALUES ('platform', 'null2');''');
        // Indexes for efficient searching
        await txn.execute('CREATE INDEX idx_keyword_id ON MovieKeywords(keyword_id)');
        await txn.execute('CREATE INDEX idx_movie_id ON MovieKeywords(movie_id)');
      });
    },
  );
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

Future<String> getConfig(String key) async {
  print("getConfig of key:  " + key);
  List<Map<String, dynamic>> config = await db.query('Config', where: 'id = ?', whereArgs: [key]);
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
  // String writeFilePath = '$filmFolder/config';
  // String data = '''
  // {
  //   "bookMarks": "$bookMark",
  //   "films_folder": "$filmFolder",
  //   "last_db_modified": "${DateTime.now().toIso8601String()}"
  // },
  // ''';
  // writeDataToFile(filmFolder, "user_default.txt", data);
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

