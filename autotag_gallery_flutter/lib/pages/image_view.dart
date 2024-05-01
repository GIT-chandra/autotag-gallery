import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class ImageData {
  final String path;
  final String name;

  const ImageData(this.path, this.name);
}

class ImageViewPage extends StatelessWidget {
  const ImageViewPage({super.key, required this.imgdata});
  final ImageData imgdata;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(imgdata.name),
      ),
      body: Center(child: Image.file(File(imgdata.path))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          OpenFilex.open(imgdata.path);
        },
        child: const Icon(Icons.open_in_new),
      ),
    );
  }
}
