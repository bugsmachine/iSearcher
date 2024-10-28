import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

void addSubtitleToVideo(String videoPath, String subtitlePath, String outputPath) {
  final command = '-i "$videoPath" -i "$subtitlePath" -c copy -c:s srt -f matroska "$outputPath"';

  FFmpegKit.execute(command).then((session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      print("Success: Subtitle added to video at $outputPath");
    } else if (ReturnCode.isCancel(returnCode)) {
      print("Operation cancelled");
    } else {
      print("Error: Failed to add subtitle");
    }
  });
}

bool moveFile(String sourcePath, String destinationPath) {
  try {
    final sourceFile = File(sourcePath);
    final destinationFile = File(destinationPath);
    sourceFile.renameSync(destinationFile.path);
    return true;
  } catch (e) {
    print("Error moving file: $e");
    return false;
  }
}