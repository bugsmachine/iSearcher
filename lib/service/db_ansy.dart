import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';


Future<void> downloadDB() async {
  // Define the URL and headers
  final url = Uri.parse('http://localhost:8080/api/db/download');
  final headers = {
    'Authorization': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzI0NzA5MjAsImlhdCI6MTczMTQzNDEyMCwiZW1haWwiOiJjQGMuY29tIiwidXNlcl9uYW1lIjoiYyIsInVzZXJfaWQiOiIxIiwicGVybWlzc2lvbnMiOlsidXNlciJdfQ.vJsoDhV4RSwGQr3k1NoRNRy6k9grMtjhjcJGN4KCLuA', // Replace with your actual token
  };

  final String sandboxedPath = Platform.environment['HOME'] ?? '';

  // get the documents directory
  final documentsDirectory = Directory(sandboxedPath);


  // final appSupport = await getApplicationSupportDirectory();
  // print('appSupport: $appSupport');
  // final appFolderPath = path.join(appSupport.path, 'iSearcher');
  //
  // // Create the folder if it doesn't exist
  // final appFolder = Directory(appFolderPath);
  // if (!await appFolder.exists()) {
  //   await appFolder.create(recursive: true);
  // }

  try {
    // Send the GET request
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Get the user's home directory
      Directory homeDir = Directory(Platform.environment['HOME']!);

      // Specify the path to the shared folder
      String sharedFolderPath = join(homeDir.path, 'shared_folder');
      String newDBFolderPath = join(sharedFolderPath, 'newDB');

      // Create the folder if it doesn't exist
      Directory newDBFolder = Directory(newDBFolderPath);
      if (!await newDBFolder.exists()) {
        await newDBFolder.create(recursive: true);
      }

      // Define the file path
      String filePath = join(newDBFolderPath, 'downloaded_database.db');

      // Write the file
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print('File downloaded and saved to $filePath');
    } else {
      print('Failed to download file: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading file: $e');
  }
}