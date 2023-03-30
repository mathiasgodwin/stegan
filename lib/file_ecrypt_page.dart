import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stegan/encryption_success_page.dart';
import 'package:stegan/file_decrypt_success_page.dart';
import 'package:stegan/image_viewer.dart';
import 'package:stegify/stegify.dart';

/// TODO: Finish the docs
/// FileEmbedPage to...
class FileEmbedPage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'FileEmbed';

  FileEmbedPage({
    required this.image,
    required this.file,
  });
  final File image;
  final File file;

  /// Static method to return the widget as a PageRoute
  static Route go({
    required File imageFile,
    required File file,
  }) =>
      MaterialPageRoute<void>(
          builder: (_) => FileEmbedPage(
                image: imageFile,
                file: file,
              ));

  final _secretKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 300, child: ImageWidget(image: image)),
              Text(file.path),
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
              const SizedBox(
                height: 20,
              ),
              _EncryptButton(
                file: file,
                keyController: _secretKeyController,
                imageFile: image,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncryptButton extends StatefulWidget {
  const _EncryptButton({
    super.key,
    required this.file,
    required this.keyController,
    required this.imageFile,
  });
  final File file;
  final TextEditingController keyController;
  final File imageFile;

  @override
  State<_EncryptButton> createState() => _EncryptButtonState();
}

class _EncryptButtonState extends State<_EncryptButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const CircularProgressIndicator.adaptive()
        : ElevatedButton(
            onPressed: () async {
              if (widget.keyController.value.text.isEmpty) return;
              setState(() {
                isLoading = true;
              });
              final file = await Stegify.encodeFile(
                fileToEmbed: widget.file,
                image: File(widget.imageFile.path),
                encryptionKey: widget.keyController.value.text,
              );
              print(file);

              if (file == null) return;
              // get status permission
              final status = await Permission.storage.status;

              // check status permission
              if (status.isDenied) {
                // request permission
                await Permission.storage.request();
            
              }

              // Save image
              await FolderFileSaver.saveImage(
                pathImage: file.path,
              );

              setState(() {
                isLoading = false;
              });

              // Navigate to success page
              Navigator.of(context).push(EncryptionSuccessPage.go());
            },
            child: const Text('Encrypt'),
          );
  }
}
