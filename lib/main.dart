// ignore_for_file: prefer_const_literals_to_create_immutables, unused_element, prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' as sz;
import 'package:path_provider/path_provider.dart';
import 'package:stegan/decrypt_message_page.dart';
import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/fingerprint_page.dart';
import 'package:stegan/message_input_page.dart';
import 'package:stegan/utils/theme.dart';
import 'package:stegify/stegify.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encrypt your message',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: FingerprintPage(),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);
  static Route go() => MaterialPageRoute<void>(builder: (_) => Home());

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _textEditController = TextEditingController();
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: const Text(
                    'Full name',
                  ),
                ),
                Flexible(
                  child: Text(
                    'Matric',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Center(
              child: Icon(
                Icons.security,
                color: Colors.green,
                size: 300,
              ),
            ),
            _EncryptDecryptButton(),
          ],
        ));
  }
}

class _GetImageButton extends StatelessWidget {
  _GetImageButton({Key? key, required this.onValue}) : super(key: key);

  final ValueChanged<XFile?> onValue;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final imageFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        onValue(imageFile);
      },
      child: Text('Get Image'),
    );
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
                normalizeOutputPath(
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

class _DecodeMessageButton extends StatelessWidget {
  _DecodeMessageButton({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final image =
            await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image == null) return;
        Navigator.of(context).push(DecryptMessagePage.go(imageFile: image));
      },
      child: Text('Decrypt'),
    );
  }
}

String normalizeOutputPath({
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

class _EncryptDecryptButton extends StatelessWidget {
  const _EncryptDecryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_EncryptButton(), _DecodeMessageButton()],
    );
  }
}

class _EncryptButton extends StatelessWidget {
  const _EncryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
            context: context,
            builder: (context) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _ImageFromCameraButton(onFile: (value) {
                      if (value == null) return;
                      Navigator.of(context)
                          .push(MessageInputPage.go(imageFile: value));
                    }),
                    _ImageFromGalleryButton(
                      onFile: (value) {
                        if (value == null) return;
                        Navigator.of(context)
                            .push(MessageInputPage.go(imageFile: value));
                      },
                    )
                  ],
                ),
              );
            });
      },
      child: Text("Encrypt"),
    );
  }
}

class _DecryptButton extends StatelessWidget {
  const _DecryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final file = await ImagePicker().pickImage(
            source: ImageSource.gallery, maxHeight: 400, maxWidth: 480);
        print(file);
        if (file == null) return;
        Navigator.of(context).push(DecryptMessagePage.go(imageFile: file));
      },
      child: Text("Decrypt"),
    );
  }
}

class _ImageFromGalleryButton extends StatelessWidget {
  final ValueChanged<XFile?> onFile;
  const _ImageFromGalleryButton({required this.onFile});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(maximumSize: Size(160, 130)),
      onPressed: () async {
        final file = await ImagePicker().pickImage(
            source: ImageSource.gallery, maxHeight: 640, maxWidth: 480);
        onFile(file);
      },
      child: Row(
        children: const [
          Icon(Icons.image_rounded),
          Text('Gallery'),
        ],
      ),
    );
  }
}

class _ImageFromCameraButton extends StatelessWidget {
  final ValueChanged<XFile?> onFile;
  const _ImageFromCameraButton({required this.onFile});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(maximumSize: Size(160, 130)),
      onPressed: () async {
        final file = await ImagePicker().pickImage(
            source: ImageSource.camera, maxHeight: 360, maxWidth: 480);

        onFile(file);
      },
      child: Row(
        children: const [
          Icon(Icons.camera_enhance),
          Text('Camera'),
        ],
      ),
    );
  }
}

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
                Row(
                  children: [Text('Enter message')],
                ),
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
                                            Row(
                                              children: [
                                                Text("Enter secret key")
                                              ],
                                            ),
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
    print(_secretKeyController.text);
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
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(
            image.path,
          ),
        ),
      ),
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
