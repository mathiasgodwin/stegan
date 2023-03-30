// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:stegan/main.dart';

/// TODO: Finish the docs
/// FileDecryptionSuccessPage to...
class FileDecryptionSuccessPage extends StatelessWidget {
  /// Static named route for page
  static const String route = 'FileDecryptionSuccess';

  /// Static method to return the widget as a PageRoute
  static Route go() =>
      MaterialPageRoute<void>(builder: (_) => FileDecryptionSuccessPage());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.thumb_up_rounded,
              size: 90,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: Text(
                'File decryption successful '
                'Check your document folder for your image',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  Home.go(),
                  (route) => false,
                );
              },
              child: Text('Home'),
            )
          ],
        ),
      ),
    );
  }
}
