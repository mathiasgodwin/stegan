library stegify;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:igodo/igodo.dart';
import 'package:image/image.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as crypto;

class Stegify {
  static Future<File?> encodeFile({
    required File image,
    required File fileToEmbed,
    String? unencryptedPrefix,
    String? outputFilePath,
    String? encryptionKey,
  }) async {
    _assertIsImage(image);

    try {
      final encodedImage = await _encodeToPng(image);

      final size = ImageSizeGetter.getSize(FileInput(image));
      final path = await getTemporaryDirectory();

      String messageToEmbed = base64Encode(fileToEmbed.readAsBytesSync());
      String extension = Util.getExtension(fileToEmbed.path);

      if (encryptionKey != null) {
        messageToEmbed = encrypt(
          token: encryptionKey,
          msg: messageToEmbed,
        );

        extension = encrypt(
          token: encryptionKey,
          msg: extension,
        );
      }

      if (unencryptedPrefix != null) {
        messageToEmbed = jsonEncode({unencryptedPrefix: messageToEmbed});
      }

      final imageWithHiddenMessage = Image.fromBytes(
        size.width,
        size.height,
        await encodedImage!.getBytes(),
        textData: {
          encryptionKey!: messageToEmbed,
          Util.FILE_EXTENSION_KEY: extension,
        },
      );

      final imageBytes = await encodePng(imageWithHiddenMessage);

      final file = File(
        normalizeOutputPath(
          inputFilePath: image.path,
          outputPath:
              "steg_${path.path}${DateTime.now().toIso8601String().toLowerCase()}",
        ),
      );

      return await file.writeAsBytes(imageBytes);
    } catch (e) {
      print(e);
    }
  }

  static Future<File?> decodeFile({
    required File image,
    String? unencryptedPrefix,
    String? encryptionKey,
  }) async {
    try {
      _assertIsPng(image);
      final decodedImage = decodePng(await image.readAsBytes());

      //

      String encodedFile = decodedImage?.textData?[encryptionKey] ?? "";

      String extension = decodedImage?.textData?[Util.FILE_EXTENSION_KEY] ?? "";

      if (encodedFile.isEmpty || extension.isEmpty) return null;

      if (encryptionKey != null) {
        encodedFile = _handleDecryption(
          key: encryptionKey,
          message: encodedFile,
          unencryptedPrefix: unencryptedPrefix,
        );
        extension = _handleDecryption(
          key: encryptionKey,
          message: extension,
        );
      }

      final file = File(Util.generatePath(image.path, extension));
      final bytes = base64Decode(encodedFile);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e, trace) {
      _handleException(e, trace);
    }
  }

  // Encode the image file
  static Future<File?> encode({
    required File imageFile,
    required String message,
    String? outputFilePath,
    String? encryptionKey,
  }) async {
    final size = ImageSizeGetter.getSize(FileInput(imageFile));
    final path = await getTemporaryDirectory();
    //
    final encodedImage = await _encodeToPng(imageFile);
    final encryptedMessage = encrypt(msg: message, token: encryptionKey!);
    final image = Image.fromBytes(
        size.width, size.height, await encodedImage!.getBytes(),
        textData: {encryptionKey: encryptedMessage});
    final newImage = encodePng(image);
    final file = File(
      normalizeOutputPath(
        inputFilePath: imageFile.path,
        outputPath: outputFilePath ??
            "steg_${path.path}${DateTime.now().toIso8601String()}",
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
      final data = decodedImage.textData?[encryptionKey];
      if (data != null) {
        final decryptedMessage = decrypt(msg: data, token: encryptionKey!);
        return decryptedMessage;
      }
      return data;
    }
  }

  static String encrypt({required String msg, required String token}) {
    crypto.Key key = crypto.Key.fromUtf8(padKey(token));
    //
    crypto.IV iv = crypto.IV.fromLength(16);
    //
    crypto.Encrypter encrypter =
        crypto.Encrypter(crypto.AES(key, padding: null));
    crypto.Encrypted encrypted = encrypter.encrypt(msg, iv: iv);
    msg = encrypted.base64;

    return msg;
  }

  static String decrypt({
    required String token,
    required String msg,
  }) {
    crypto.Key key = crypto.Key.fromUtf8(padKey(token));

    crypto.IV iv = crypto.IV.fromLength(16);

    crypto.Encrypter encrypter =
        crypto.Encrypter(crypto.AES(key, padding: null));
    final decryptedMessage =
        encrypter.decrypt(crypto.Encrypted.fromBase64(msg), iv: iv);

    return decryptedMessage;
  }

  static String padKey(String key) {
    if (key.length > 32) {
      throw FlutterError('cryption_key_length_greater_than_32');
    }
    String paddedKey = key;
    int padCnt = 32 - key.length;
    for (int i = 0; i < padCnt; ++i) {
      paddedKey += '#';
    }
    return paddedKey;
  }

  static String normalizeOutputPath({
    required String inputFilePath,
    String? outputPath,
  }) {
    try {
      if (Util.getExtension(outputPath!) == "png") {
        return outputPath;
      }
    } catch (e, s) {}
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
        "${image.path} is not a supported file type$trace",
      );
    }
  }

  static void _handleException(Object e, [StackTrace? trace]) {
    if (e is Exception) throw e;
  }

  static void _assertIsImage(File image) {
    if (!Util.isImage(image.path)) {
      throw Exception(
        "${image.path} is not a supported file type",
      );
    }
  }

  static void _assertIsPng(File image) {
    if (Util.getExtension(image.path) != "png") {
      throw Exception(
        "${image.path} is not a supported file type for decoding",
      );
    }
  }

  // static String _encrypt({
  //   required String key,
  //   required String message,
  // }) {
  //   return Igodo.encrypt(message, key);

  //   // final rsaPublicKey = RSAPublicKey.fromString(key);
  //   // return rsaPublicKey.encrypt(message);
  // }

  // static String _decrypt({
  //   required String key,
  //   required String message,
  // }) {
  //   return Igodo.decrypt(message, key);

  //   // final rsaPrivateKey = RSAPrivateKey.fromString(key);
  //   // return rsaPrivateKey.decrypt(message);
  // }

  static String _verifyUnencryptedPrefixAndDecrypt({
    required String key,
    required String message,
    required String unencryptedPrefix,
  }) {
    String encryptedMessage = message;
    if (unencryptedPrefix.isNotEmpty) {
      final decodedMessage =
          jsonDecode(encryptedMessage) as Map<String, dynamic>;
      if (decodedMessage.keys.first == unencryptedPrefix) {
        encryptedMessage = (decodedMessage).values.first;
        return decrypt(
          token: key,
          msg: encryptedMessage,
        );
      }
    }
    return "";
  }

  static String _handleDecryption({
    required String key,
    required String message,
    String? unencryptedPrefix,
  }) {
    if (unencryptedPrefix != null) {
      return _verifyUnencryptedPrefixAndDecrypt(
        key: key,
        message: message,
        unencryptedPrefix: unencryptedPrefix,
      );
    }

    return decrypt(
      token: key,
      msg: message,
    );
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
      final fileName = "${DateTime.now().toIso8601String().toLowerCase()}.$ext";

      final splitPath = path.split(Platform.pathSeparator);
      splitPath.removeLast();

      if (splitPath.isEmpty) {
        return fileName;
      }
      return "${splitPath.join("/")}/$fileName";
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
