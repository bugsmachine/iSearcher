import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


// Initialize the database
Future<Database> initDatabase() async {
  print("initDatabase");
  return openDatabase(
    join(await getDatabasesPath(), 'movies_database.db'),
    version: 3, // Increment the version number
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
      CREATE TABLE MovieKeywords (
        movie_id INTEGER,
        keyword_id INTEGER,
        FOREIGN KEY(movie_id) REFERENCES Movies(id),
        FOREIGN KEY(keyword_id) REFERENCES Keywords(id),
        PRIMARY KEY (movie_id, keyword_id)
      )
    ''');

        await txn.execute('CREATE INDEX idx_keyword_id ON MovieKeywords(keyword_id)');
        await txn.execute('CREATE INDEX idx_movie_id ON MovieKeywords(movie_id)');
      });
    },
  );
}
Future<void> printAll(Database db) async{
  print("printAll");
  await printAllMovies(db);
  await printAllKeywords(db);
  await printAllMovieKeywords(db);
}

// Function to print all data in the Movies table
Future<void> printAllMovies(Database db) async {
  List<Map<String, dynamic>> movies = await db.query('Movies');
  for (var movie in movies) {
    print('Movie ID: ${movie['id']}, Path: ${movie['path']}');
  }
}

// Function to print all data in the MovieKeywords table
Future<void> printAllMovieKeywords(Database db) async {
  List<Map<String, dynamic>> movieKeywords = await db.query('MovieKeywords');
  for (var movieKeyword in movieKeywords) {
    print('Movie ID: ${movieKeyword['movie_id']}, Keyword ID: ${movieKeyword['keyword_id']}');
  }
}

// Function to print all data in the Keywords table
Future<void> printAllKeywords(Database db) async {
  List<Map<String, dynamic>> keywords = await db.query('Keywords');
  for (var keyword in keywords) {
    print('Keyword ID: ${keyword['id']}, Keyword: ${keyword['keyword']}');
  }
}

// Function to insert a movie and its associated keywords
Future<void> insertMovie(Database db, String path, List<String> keywords) async {

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
Future<List<Map<String, dynamic>>> searchMoviesByKeyword(Database db, String keyword) async {
  print("searchMoviesByKeyword     " + keyword);
  return await db.rawQuery('''
    SELECT Movies.path
    FROM Movies
    JOIN MovieKeywords ON Movies.id = MovieKeywords.movie_id
    JOIN Keywords ON MovieKeywords.keyword_id = Keywords.id
    WHERE Keywords.keyword = ?
  ''', [keyword]);
}

