// ignore_for_file: prefer_const_literals_to_create_immutables, unused_element, prefer_const_constructors

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stegan/file_ecrypt_page.dart';
import 'package:stegan/image_viewer.dart';
import 'package:stegan/message_decrypt_page.dart';
import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/fingerprint_page.dart';
import 'package:stegan/message_encrypt_page.dart';
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
  void initState() {
    super.initState();
    checkPermission();
  }

  checkPermission() async {
    // get status permission
    final status = await Permission.storage.status;

    // check status permission
    if (status.isDenied) {
      // request permission
      await Permission.storage.request();
    }
  }

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
                    'Matric Number',
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

class _EncryptDecryptButton extends StatelessWidget {
  const _EncryptDecryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_EncryptButton(), _DecryptButton()],
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
                      showADialog(context, value);
                    }),
                    _ImageFromGalleryButton(
                      onFile: (value) {
                        if (value == null) return;
                        showADialog(context, value);
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

  showADialog(BuildContext context, File? image) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SingleChildScrollView(
              physics: ScrollPhysics(),
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        Navigator.of(context).push(FileEmbedPage.go(
                          imageFile: image!,
                          file: File(result.files.single.path!),
                        ));
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.file_upload),
                        Text('Embed File'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(MessageInputPage.go(imageFile: image!));
                    },
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet_sharp),
                        Text('Embed Text'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class _DecryptButton extends StatelessWidget {
  const _DecryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await FilePicker.platform
            .pickFiles(type: FileType.image, allowCompression: false);
        if (result == null) return;

        final filePath = result.files.single.path;
        final file = File(filePath!);

        showADialog(context, file);
      },
      child: Text("Decrypt"),
    );
  }

  showADialog(BuildContext context, File? image) {
    final theme = Theme.of(context);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SingleChildScrollView(
              physics: ScrollPhysics(),
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).push(DecryptMessagePage.go(
                        imageFile: image!,
                        type: DecryptType.file,
                      ));
                    },
                    child: Row(
                      children: [
                        Icon(Icons.file_upload),
                        Text('Decrypt File'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(DecryptMessagePage.go(
                          imageFile: image!, type: DecryptType.text));
                    },
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet_sharp),
                        Text('Decrypt Text'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class _ImageFromGalleryButton extends StatelessWidget {
  final ValueChanged<File?> onFile;
  const _ImageFromGalleryButton({required this.onFile});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(maximumSize: Size(160, 130)),
      onPressed: () async {
        final file = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowCompression: false,
        );
        onFile(File(file!.files.single.path!));

        // onFile(File.fromRawPath(file!.files.single.bytes!));
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
  final ValueChanged<File?> onFile;
  const _ImageFromCameraButton({required this.onFile});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(maximumSize: Size(160, 130)),
      onPressed: () async {
        final file = await ImagePicker().pickImage(
            source: ImageSource.camera, maxHeight: 360, maxWidth: 480);
        if (file == null) return;
        final newFile = File(file.path);
        onFile(newFile);
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
