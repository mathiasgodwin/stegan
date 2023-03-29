// ignore_for_file: prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_steganography/decoder.dart';
// import 'package:flutter_steganography/requests/requests.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stegify/stegify.dart';

/// TODO: Finish the docs
/// DecryptMessagePage to...
class DecryptMessagePage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'MessageInput';
  DecryptMessagePage({required this.image});
  final XFile image;

  /// Static method to return the widget as a PageRoute
  static Route go({required XFile imageFile}) => MaterialPageRoute<void>(
      builder: (_) => DecryptMessagePage(
            image: imageFile,
          ));

  final _secretKeyController = TextEditingController();
  final _secretFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _secretFormKey,
            child: Column(
              children: [
                _ImageWidget(
                  image: image,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Enter secret key'),
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

                            final embeddedMessage = await usingStegify();

                            if (embeddedMessage == null) {
                              ScaffoldMessenger.of(context)
                                  // ignore: prefer_const_constructors
                                  .showSnackBar(SnackBar(
                                content: const Text(
                                    'Error decrypting, pls verify it was encrypted by this app'),
                              ));
                              return;
                            }

                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('You secret message'),
                                    content: SingleChildScrollView(
                                      physics: ScrollPhysics(),
                                      child: Container(
                                        child: Text(embeddedMessage),
                                      ),
                                    ),
                                  );
                                });
                          }
                        } catch (e, s) {
                          print(e);
                          print(s);
                        }
                      },
                      child: const Text('Decrypt'));
                })
              ],
            ),
          )),
    );
  }

  Future<String?> usingStegify() async {
    final ImageFile = File(image.path);
    final message = await Stegify.decode(
      image: ImageFile,
      encryptionKey: _secretKeyController.text,
    );
    return message;
  }

}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.image});
  final XFile image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(image.path),
        height: 300,
      ),
    );
  }
}
