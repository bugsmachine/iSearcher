import 'dart:io';

Future<Map<String, String>> readUserDefaults(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  final Map<String, String> userDefaults = {};

  for (var line in lines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      final value = parts[1].trim().replaceAll('"', '');
      userDefaults[key] = value;
    }
  }

  return userDefaults;
}

Future<String?> getUserDefault(String filePath, String key) async {
  final file = File(filePath);
  final lines = await file.readAsLines();

  for (var line in lines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      final currentKey = parts[0].trim();
      if (currentKey == key) {
        return parts[1].trim().replaceAll('"', '');
      }
    }
  }
  return null;
}

Future<void> setUserDefault(String filePath, String key, String value) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  bool keyFound = false;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('=')) {
      final parts = lines[i].split('=');
      final currentKey = parts[0].trim();
      if (currentKey == key) {
        lines[i] = '$key="$value";';
        keyFound = true;
        break;
      }
    }
  }

  if (!keyFound) {
    lines.add('$key="$value";');
  }

  await file.writeAsString(lines.join('\n'));
}


void main() async {

    const filePath = 'lib/user_default/user_default.txt';

    // Get a value
    String? value = await getUserDefault(filePath, 'films_folder');
    print('Value for key "abc": $value');

    // Set a value
    // await setUserDefault(filePath, 'abc', '1');
    // print('Updated value for key "abc"');
    //
    // // Verify the update
    // value = await getUserDefault(filePath, 'abc');
    // print('Value for key "abc" after update: $value');
}