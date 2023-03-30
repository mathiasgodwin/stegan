// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';

import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/image_viewer.dart';
import 'package:stegify/stegify.dart';

import 'package:image_size_getter/image_size_getter.dart' as sz;
import 'package:stegan/message_decrypt_page.dart';
import 'package:stegify/stegify.dart';

/// TODO: Finish the docs
/// MessageInputPage to...
class MessageInputPage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'MessageInput';
  MessageInputPage({super.key, required this.image});
  final File image;

  /// Static method to return the widget as a PageRoute
  static Route go({required File imageFile}) => MaterialPageRoute<void>(
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
                SizedBox(
                  height: 300,
                  child: ImageWidget(
                    image: image,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Enter message to encrypt'),
                  ],
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
                              return AlertDialog(
                                content: Form(
                                  key: _secretFormKey,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Enter Secret Key',
                                        style: theme.textTheme.headlineSmall,
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
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
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
    final file = await Stegify.encode(
      imageFile: imageFile,
      message: _messageController.text,
      encryptionKey: _secretKeyController.text,
    );
    if (file == null) return;
    await FolderFileSaver.saveImage(
      pathImage: file.path,
    );
  }
}
