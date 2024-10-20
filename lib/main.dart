import 'dart:convert';
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import 'package:home_cinema_app/view/all_movies_view.dart';
import 'package:home_cinema_app/view/unrecorded_films_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
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

  runApp(const MyApp());



  // print("name"+getMacOSUsername());
  const platform1 = MethodChannel('com.example.app/settings');

  platform1.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'openSettings') {
      openSettingsWindow();
    }
  });
}




// Future<void> startFlaskServer() async {
//   final process = await Process.start('/usr/bin/python3', ['-c', '''
// from flask import Flask, request, send_file, jsonify
// import requests
// from io import BytesIO
//
// app = Flask(__name__)
//
// @app.route('/image', methods=['GET'])
// def download_image():
//     image_path = request.args.get('image_path')
//     if not image_path:
//         return jsonify({"error": "No image path provided"}), 400
//
//     url = f"https://image.tmdb.org/t/p/w500/{image_path}"
//     response = requests.get(url)
//
//     if response.status_code == 200:
//         img = BytesIO(response.content)
//         return send_file(img, mimetype='image/jpeg', as_attachment=True, download_name='downloaded_image.jpg')
//     else:
//         return jsonify(
//             {"error": f"Failed to download image. Status code: {response.status_code}"}), response.status_code
//
// if __name__ == '__main__':
//     app.run(debug=True)
// ''']);
//   process.stdout.transform(utf8.decoder).listen((data) {
//     print(data);
//   });
//   process.stderr.transform(utf8.decoder).listen((data) {
//     print(data);
//   });
// }

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
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.grey[105]),
            onPressed: () {
              print("Filter icon clicked!");
            },
          ),
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

