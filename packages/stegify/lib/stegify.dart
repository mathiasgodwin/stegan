library stegify;

import 'dart:io';
import 'package:image/image.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';

class Stegify {
  // Encode the image file
  static Future<File?> encode({
    required File imageFile,
    required String message,
    String? outputFilePath,
    String? encryptionKey,
  }) async {
    final size = ImageSizeGetter.getSize(FileInput(imageFile));
    final path = await getTemporaryDirectory();

    final encodedImage = await _encodeToPng(imageFile);

    final image = Image.fromBytes(
        size.width, size.height, await encodedImage!.getBytes(),
        textData: {Util.SECRET_KEY: message});
    final newImage = encodePng(image);
    final file = File(
      normalizeOutputPath(
        inputFilePath: imageFile.path,
        outputPath:
            outputFilePath ?? path.path + DateTime.now().toIso8601String(),
      ),
    );
    return await file.writeAsBytes(newImage);
  }

  static Future<String?> decode({
    required File image,
    String? encryptionKey,
  }) async {
    final decodedImage = decodePng(await image.readAsBytes());
    if (decodedImage!.textData != null) {
      final data = decodedImage.textData?['name'];
      return data;
    }
  }

  static String normalizeOutputPath({
    required String inputFilePath,
    String? outputPath,
  }) {
    try {
      if (Util.getExtension(outputPath!) == "png") {
        return outputPath;
      }
    } catch (e) {}
    return Util.generatePath(inputFilePath);
  }

  static Future<Image?> _encodeToPng(File image) async {
    try {
      final extension = Util.getExtension(image.path);

      switch (extension) {
        case "png":
          return decodePng(await image.readAsBytes());
        case "jpg":
        case "jpeg":
          final jpgImage = decodeJpg(await image.readAsBytes());
          final size = ImageSizeGetter.getSize(FileInput(image));

          final img = Image.fromBytes(
            size.width,
            size.height,
            jpgImage!.getBytes(),
          );

          final pngBytes = encodePng(img);

          return decodePng(pngBytes);
      }
    } catch (e, trace) {
      throw Exception(
        "${image.path} is not a supported file type" + trace.toString(),
      );
    }
  }
}

class Util {
  static const SECRET_KEY = "x-encrypted-message";
  static const FILE_EXTENSION_KEY = "x-file-extension";

  static bool isImage(String path) {
    return _allowedExtensions.contains(
      getExtension(path),
    );
  }

  static String getExtension(String path) {
    try {
      return path
          .split(Platform.pathSeparator)
          .last
          .split(".")
          .last
          .toLowerCase();
    } catch (e) {
      throw Exception("Invalid file: $path");
    }
  }

  static String generatePath(String path, [String ext = "png"]) {
    try {
      final fileName = DateTime.now().toIso8601String() + ".$ext";

      final splitPath = path.split(Platform.pathSeparator);
      splitPath.removeLast();

      if (splitPath.isEmpty) {
        return fileName;
      }
      return splitPath.join("/") + "/$fileName";
    } catch (e) {
      throw Exception("Invalid file: $path");
    }
  }

  static const List<String> _allowedExtensions = [
    "png",
    "jpg",
    "jpeg",
  ];
}
