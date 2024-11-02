import 'dart:convert';
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import 'package:home_cinema_app/view/all_movies_view.dart';
import 'package:home_cinema_app/view/unrecorded_films_view.dart';
import 'package:home_cinema_app/web_server/server_main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'component/pop_up_menu.dart';
import 'repository/db.dart';
import 'service/main_service.dart';
import 'package:home_cinema_app/app_config/colors.dart';
import '../component/modal.dart';
import 'view/settings.dart';
import 'package:http/http.dart' as http;


void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // IGNORE THIS IN MACOS
  // // Initialize FFI
  // sqfliteFfiInit();
  //
  // // Set the database factory
  // databaseFactory = databaseFactoryFfi;

  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty ? const {} : jsonDecode(args[2]) as Map<String, dynamic>;

    if (arguments['view'] == 'settings') {
      runApp(SettingsApp());
    } else {
      // Handle other potential windows here
    }
    return;
  }

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Remove the title bar
  if (Platform.isMacOS) {
    WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // control windows size
      await windowManager.setSize(const Size(1100, 700));
      await windowManager.setPosition(const Offset(230, 120));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // await startFlaskServer();


  await initDatabase();

  //check the running platform
  String platform = await getConfig("platform");
  if(platform == "null2") {
    if (Platform.isWindows) {
      updateConfig("platform", "windows");
    } else {
      updateConfig("platform", "macos");
    }
  }

  await FFmpegKitConfig.init();
  runApp(const MyApp());

  // await executePythonScript();
  // await checkPythonInstallation();


  // print(getMacOSUsername());

  await startServer();

  if (Platform.isWindows) {
    initWindowAppDataForder();
    await startFlaskServer();
  }


  // print("name"+getMacOSUsername());
  const platform1 = MethodChannel('com.example.app/settings');

  platform1.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'openSettings') {
      openSettingsWindow();
    }
  });


}

void initWindowAppDataForder() async {
  String appDataPath = Platform.environment['LOCALAPPDATA'] ?? '';
  String appDataFolder = '$appDataPath\\iSearcher';
  Directory appDataDir = Directory(appDataFolder);
  if (!appDataDir.existsSync()) {
    appDataDir.createSync();
  }

  String posterCacheFolder = '$appDataFolder\\Posters';
  Directory posterCacheDir = Directory(posterCacheFolder);
  if (!posterCacheDir.existsSync()) {
    posterCacheDir.createSync();
  }
}

// Future<void> checkPythonInstallation() async {
//   try {
//     final result = await Process.run('python', ['--version']);
//     if (result.stdout.isNotEmpty) {
//       print('Python version: ${result.stdout}');
//     }
//     if (result.stderr.isNotEmpty) {
//       print('Error: ${result.stderr}');
//     }
//   } catch (e) {
//     print('Error checking Python installation: $e');
//   }
// }
//
//
// Future<void> executePythonScript() async {
//   print('Executing Python script...');
//   try {
//     final result = await Process.run('python', ['-u', '-c', 'print("Hello from Python script!")']);
//
//
//     // Capture stdout and stderr
//     if (result.stdout.isNotEmpty) {
//       print('Python script output: ${result.stdout}');
//     }
//     if (result.stderr.isNotEmpty) {
//       print('Python script error: ${result.stderr}');
//     }
//   } catch (e) {
//     print('Error executing Python script: $e');
//   }
// }




Future<void> startFlaskServer() async {
  // Ensure Flask is installed
  try {
    final result = await Process.run('python', ['-m', 'pip', 'install', 'flask', 'requests']);
    if (result.stdout.isNotEmpty) {
      print('Pip output: ${result.stdout}');
    }
    if (result.stderr.isNotEmpty) {
      print('Pip error: ${result.stderr}');
    }
  } catch (e) {
    print('Error installing Flask: $e');
    return;
  }

  // Start the Flask server
  final process = await Process.start('python', ['-u', '-c', '''
from flask import Flask, request, send_file, jsonify
import requests
from io import BytesIO
import os

app = Flask(__name__)

@app.route('/fetch_and_download_poster', methods=['GET'])
def fetch_and_download_poster():
    movie_title = request.args.get('movieTitle')
    store_path = request.args.get('storePath')
    print(f"Movie title: {movie_title}, Store path: {store_path}")
    
    if not movie_title:
        return jsonify({"error": "No movie title provided"}), 400
    if not store_path:
        return jsonify({"error": "No store path provided"}), 400

    api_key = '15d2ea6d0dc1d476efbca3eba2b9bbfb'
    url = f'https://api.themoviedb.org/3/search/movie?api_key={api_key}&query={movie_title}'

    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if data['results'] and len(data['results']) > 0:
            poster_path = data['results'][0]['poster_path']
            image_url = f'https://image.tmdb.org/t/p/w500{poster_path}'
            
            print(f"Downloading image from: {image_url}")
            # Download the image
            image_response = requests.get(image_url)
            if image_response.status_code == 200:
                image_path = os.path.join(store_path, poster_path.strip('/'))
                print(f"Saving image to: {image_path}")
                os.makedirs(os.path.dirname(image_path), exist_ok=True)
                
                with open(image_path, 'wb') as f:
                    f.write(image_response.content)
                
                return jsonify({"message": "Image successfully saved", "imagePath": image_path}), 200
            else:
                return jsonify({"error": f"Failed to download image. Status code: {image_response.status_code}"}), image_response.status_code
        else:
            return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=No+Poster+Found'})
    else:
        return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=Error+Fetching+Poster'}), response.status_code



@app.route('/image', methods=['GET'])
def download_image():
    image_path = request.args.get('image_path')
    if not image_path:
        return jsonify({"error": "No image path provided"}), 400

    url = f"https://image.tmdb.org/t/p/w500/{image_path}"
    response = requests.get(url)

    if response.status_code == 200:
        img = BytesIO(response.content)
        return send_file(img, mimetype='image/jpeg', as_attachment=True, download_name='downloaded_image.jpg')
    else:
        return jsonify(
            {"error": f"Failed to download image. Status code: {response.status_code}"}), response.status_code
            
@app.route('/fetch_movie_poster', methods=['GET'])
def fetch_movie_poster():
    movie_title = request.args.get('movieTitle')
    if not movie_title:
        return jsonify({"error": "No movie title provided"}), 400

    api_key = '15d2ea6d0dc1d476efbca3eba2b9bbfb'
    url = f'https://api.themoviedb.org/3/search/movie?api_key={api_key}&query={movie_title}'

    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if data['results'] and len(data['results']) > 0:
            poster_path = data['results'][0]['poster_path']
            return jsonify({"posterUrl": f'https://image.tmdb.org/t/p/w500{poster_path}'})
        else:
            return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=No+Poster+Found'})
    else:
        return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=Error+Fetching+Poster'}), response.status_code
            
@app.route('/hello', methods=['GET'])
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(debug=True,port=12139)
''']);
  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });
  process.stderr.transform(utf8.decoder).listen((data) {
    print(data);
  });
}

Future<void> openSettingsWindow() async {
  final window = await DesktopMultiWindow.createWindow(jsonEncode({
    'view': 'settings',
  }));

  window
    ..setFrame(const Offset(100, 100) & const Size(800, 400))
    ..center()
    ..setTitle('Settings')
    ..show();

}

class SettingsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SettingsWindow(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Movie Searcher',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void onWindowClose() {
    // do something
    print('Window closed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 250,
                child: _buildSidebar(),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTitleBar(),
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(
            left: 250,
            top: 0,
            bottom: 0,
            child: VerticalDivider(thickness: 1, width: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 40,
      color: Colors.white60,
      child: Row(
        children: [
          const SizedBox(width: 5),
          CustomPopupMenuButton(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.grey[105]),
                    onPressed: () {
                      print("Search icon clicked!");
                    },
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                ),
                style: TextStyle(color: AppColors.black),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.yellow),
              onPressed: () {
                CustomModal.show(
                  context,
                  'Modal Title',
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter something...',
                        ),
                      ),
                    ],
                  ),
                  [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Submit'),
                      onPressed: () {
                        // Handle submit action
                      },
                    ),
                  ],
                  width: 300,
                  height: 200,
                );
              },
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 30.0),
            child: Text(
              'iSearcher',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              backgroundColor: Colors.grey[200],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                if (index == 3) {
                  openSettingsWindow();
                }
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie),
                  label: Text('All Movies'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: Text('Unrecorded Films'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text('Category'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final imageDownloader = ImageDownloader(); // Create an instance of ImageDownloader

    switch (_selectedIndex) {
      case 0:
        return AllMoviesView();
      case 1:
        return UnrecordedFilmsView();
      case 2:
        return FutureBuilder<Image>(
          future: imageDownloader.downloadImage("y4MBh0EjBlMuOzv9axM4qJlmhzz.jpg"),
          builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return snapshot.data ?? Container();
            }
          },
        );
      case 3:
        return const Center(child: Text('Settings')); // Placeholder for settings
      default:
        return const Center(child: Text('Unknown Page'));
    }
  }


}

class ImageDownloader {
  static const platform = MethodChannel('image_download_channel');

  Future<Image> downloadImage(String imageName) async {
    try {
      final String base64Image = await platform.invokeMethod('getImage', {'imageName': imageName});
      final bytes = base64.decode(base64Image);
      return Image.memory(Uint8List.fromList(bytes));
    } catch (e) {
      print("Error downloading image: $e");
      return Image.asset('assets/err_img2.png'); // Fallback image in case of error
    }
  }

  Future<List<String>?> getImageStorageInfo() async {
    try {
      final List<String>? info = await platform.invokeMethod("info");
      print('Image storage info: $info');
      return info;
    } on PlatformException catch (e) {
      print("Error getting image storage info: '${e.message}'.");
      return null;
    }
  }
}

