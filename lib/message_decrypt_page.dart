// ignore_for_file: prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stegan/file_decrypt_success_page.dart';
import 'package:stegan/image_viewer.dart';
import 'package:stegify/stegify.dart';
import 'package:image/image.dart' as im;

enum DecryptType { text, file }

/// TODO: Finish the docs
/// DecryptMessagePage to...
class DecryptMessagePage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'MessageInput';
  DecryptMessagePage({
    required this.image,
    required this.type,
  });
  final File image;
  final DecryptType type;

  /// Static method to return the widget as a PageRoute
  static Route go({required File imageFile, required DecryptType type}) =>
      MaterialPageRoute<void>(
          builder: (_) => DecryptMessagePage(
                image: imageFile,
                type: type,
              ));

  final _secretKeyController = TextEditingController();
  final _secretFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _secretFormKey,
            child: Column(
              children: [
                ImageWidget(
                  image: image,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Enter secret key'),
                  ],
                ),
                TextFormField(
                  controller: _secretKeyController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter secret to decrypt message';
                    }
                    return null;
                  },
                ),
                Builder(builder: (context) {
                  return ElevatedButton(
                      onPressed: () async {
                        try {
                          if (_secretFormKey.currentState!.validate()) {
                            //decode with same encryption key used to encode
                            //to retrieve encrypted message
                            String? embeddedMessage;
                            if (type == DecryptType.text) {
                              embeddedMessage = await usingStegify();
                            } else {
                              final a = im.decodePng(await image.readAsBytes());

                              final file = await Stegify.decodeFile(
                                  image: File(image.path),
                                  encryptionKey: _secretKeyController.text);

                              if (file == null) return;
                              await FolderFileSaver.saveFileToFolderExt(
                                  file.path);
                              Navigator.of(context)
                                  .push(FileDecryptionSuccessPage.go());
                              return;
                            }

                            if (embeddedMessage == null) {
                              ScaffoldMessenger.of(context)
                                  // ignore: prefer_const_constructors
                                  .showSnackBar(SnackBar(
                                content: const Text(
                                    'Error decrypting, pls verify it was encrypted by this app'),
                              ));
                              return;
                            }

                            if (type == DecryptType.text) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('You secret message'),
                                      content: SingleChildScrollView(
                                        physics: const ScrollPhysics(),
                                        child: Container(
                                          child: Text(embeddedMessage ?? ''),
                                        ),
                                      ),
                                    );
                                  });
                            }
                          } else {}
                        } catch (e, s) {}
                      },
                      child: const Text('Decrypt'));
                })
              ],
            ),
          )),
    );
  }

  Future<String?> usingStegify() async {
    final imageFile = File(image.path);
    final message = await Stegify.decode(
      image: imageFile,
      encryptionKey: _secretKeyController.text,
    );
    return message;
  }
}
