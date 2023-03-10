// ignore_for_file: prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_steganography/decoder.dart';
// import 'package:flutter_steganography/requests/requests.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/message_input_page.dart';
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
                                    content: Container(
                                      child: Text(embeddedMessage),
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

  // Future<String?> usingFlutterStegan() async {
  //   print(image.path);

  //   final imageUint8File = await image.readAsBytes();
  //   print(imageUint8File);
  //   DecodeRequest request =
  //       DecodeRequest(imageUint8File, key: _secretKeyController.text.trim());
  //   String response = await decodeMessageFromImageAsync(request);
  //   String? embeddedMessage = response;
  //   print(embeddedMessage);

  //   final tempDir = await getTemporaryDirectory();
  //   File newFile = await File(
  //           '${tempDir.path}/image_${DateTime.now().toIso8601String()}.png')
  //       .create();
  //   print({'Before Wite Size': newFile.size});
  //   // await newFile.writeAsBytes(response);

  //   print({'New Size': newFile.size});
  //   return embeddedMessage;
  // }

//   Future<String?> usingStegan() async {
//     String? embeddedMessage = await Steganograph.decode(
//       image: File(image.path),
//       encryptionKey: _secretKeyController.text.trim(),
//     );

//     return embeddedMessage;
//   }
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
