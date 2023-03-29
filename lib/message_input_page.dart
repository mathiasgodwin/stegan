// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_steganography/encoder.dart';
// import 'package:flutter_steganography/requests/encode_request.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/main.dart';
import 'package:stegify/stegify.dart';

import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' as sz;
import 'package:path_provider/path_provider.dart';
import 'package:stegan/decrypt_message_page.dart';
import 'package:stegan/message_input_page.dart';
import 'package:stegan/utils/theme.dart';
import 'package:stegify/stegify.dart';

/// TODO: Finish the docs
/// MessageInputPage to...
class MessageInputPage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'MessageInput';
  MessageInputPage({required this.image});
  final XFile image;

  /// Static method to return the widget as a PageRoute
  static Route go({required XFile imageFile}) => MaterialPageRoute<void>(
      builder: (_) => MessageInputPage(
            image: imageFile,
          ));

  final _messageController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secretFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _ImageWidget(
                  image: image,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: TextFormField(
                    controller: _messageController,
                    expands: true,
                    maxLines: null,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter some message to continue';
                      }

                      return null;
                    },
                  ),
                ),
                Builder(builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        showDialog(
                            useRootNavigator: false,
                            context: context,
                            builder: (context) {
                              return Container(
                                color: Colors.transparent,
                                child: Material(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Form(
                                        key: _secretFormKey,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Enter Secret Key',
                                              style: theme.textTheme.headline5,
                                            ),
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller: _secretKeyController,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Secret key cannot be empty';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Close')),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    //
                                                    await usingStegify();

                                                    Navigator.of(context)
                                                        .pushAndRemoveUntil(
                                                            EncryptionSuccessPage
                                                                .go(),
                                                            (route) => false);
                                                  },
                                                  child: const Text('Save'),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            });
                      }
                    },
                    child: const Text('Encrypt'),
                  );
                }),
                // _SaveImageButton(
                //   imageFile: File(image.path),
                //   message: _messageController.text,
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> usingStegify() async {
    final imageFile = File(image.path);
    print(imageFile.path);
    final file = await Stegify.encode(
      imageFile: imageFile,
      message: _messageController.text,
      encryptionKey: _secretKeyController.text,
    );
    await GallerySaver.saveImage(file!.path, albumName: 'Encrypted');
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.image});
  final XFile image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(image.path)),
    );
  }
}

String getFileExtension(String fileName) {
  return "." + fileName.split('.').last;
}

extension FileUtils on File {
  get size {
    int sizeInBytes = this.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    return sizeInMb;
  }
}

class _SaveImageButton extends StatelessWidget {
  _SaveImageButton({Key? key, required this.imageFile, required this.message})
      : super(key: key);
  final File? imageFile;
  final String message;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: imageFile == null
          ? null
          : () async {
              final size = sz.ImageSizeGetter.getSize(FileInput(imageFile!));
              final path = await getTemporaryDirectory();
              final enImage = await encodeToPng(imageFile!);
              final image = img.Image.fromBytes(
                  size.width, size.height, enImage!.getBytes(),
                  textData: {Util.SECRET_KEY: message});
              final newImagePath =
                  await File(path.path + DateTime.now().toIso8601String())
                      .create();
              final newImage = img.encodePng(image);
              // final latestImage = await newImagePath.writeAsBytes(newImage);
              // print(latestImage.path);
              final file = File(
                Stegify.normalizeOutputPath(
                  inputFilePath: imageFile!.path,
                  outputPath: path.path + DateTime.now().toIso8601String(),
                ),
              );
              file.writeAsBytes(newImage);
              GallerySaver.saveImage(file.path);
            },
      child: const Text('Encrypt'),
    );
  }
}

Future<img.Image?> encodeToPng(File image) async {
  try {
    final extension = image.path
        .split(Platform.pathSeparator)
        .last
        .split(".")
        .last
        .toLowerCase();
    ;

    switch (extension) {
      case "png":
        return img.decodePng(await image.readAsBytes());
      case "jpg":
      case "jpeg":
        final jpgImage = img.decodeJpg(await image.readAsBytes());
        final size = sz.ImageSizeGetter.getSize(FileInput(image));

        final imgFile = img.Image.fromBytes(
          size.width,
          size.height,
          jpgImage!.getBytes(),
        );

        final pngBytes = img.encodePng(imgFile);

        return img.decodePng(pngBytes);
    }
  } catch (e, trace) {
    throw Exception(
      "${image.path} is not a supported file type" + trace.toString(),
    );
  }
}
