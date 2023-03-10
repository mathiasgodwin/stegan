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
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  static Route go() => MaterialPageRoute<void>(builder: (_) => Home());
  @override
  Widget build(BuildContext context) {
    final deviceData = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/landing_page_image.jpg',
            height: deviceData.height,
            width: deviceData.width,
          ),
          const Align(
              alignment: Alignment.bottomCenter,
              child: _EncryptDecryptButton()),
        ],
      ),
    );
  }
}

class _EncryptDecryptButton extends StatelessWidget {
  const _EncryptDecryptButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _EncryptButton(),
        _DecryptButton(),
      ],
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
        children: [
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
        children: [
          Icon(Icons.camera_enhance),
          Text('Camera'),
        ],
      ),
    );
  }
}
