import 'package:flutter/material.dart';
import 'dart:io';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalImageProvider extends EasyImageProvider {
  final List<String> photoPaths;
  int initialIndex;

  LocalImageProvider({required this.photoPaths, this.initialIndex = 0});

  @override
  ImageProvider<Object> imageBuilder(BuildContext context, int index) {
    String? localImagePath = photoPaths[index];
    File? imageFile;

    if (localImagePath != null) {
      imageFile = File(localImagePath);
    }

    ImageProvider imageProvider = imageFile != null
        ? FileImage(imageFile)
        : AssetImage("assets/images/product_placeholder.jpg") as ImageProvider;

    return imageProvider;
  }

  @override
  int get imageCount => photoPaths.length;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  List<String> photoPaths = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
      print("counter - " + _counter.toString());
    });
  }

  void _openImage(int idx) {
    localImageProvider.initialIndex = idx;
    showImageViewerPager(context, localImageProvider, onPageChanged: (page) {
      print("page changed to $page");
    }, onViewerDismissed: (page) {
      print("dismissed while on page $page");
    }, doubleTapZoomable: true, swipeDismissible: true);
  }

  late final LocalImageProvider localImageProvider;
  @override
  void initState() {
    super.initState();
    _getStoragePermission();
  }

  void _getStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        setState(() {
          photoPaths = [
            '/storage/emulated/0/DCIM/Camera/IMG_20240226_222211.jpg',
            '/storage/emulated/0/Download/20240313_185828.jpg',
            '/storage/emulated/0/Download/IMG_0011.JPG',
            '/storage/emulated/0/Download/IMG_0007.JPG',
            // '/storage/emulated/0/Download/IMG_0005.JPG',
            '/storage/emulated/0/Download/IMG_0001.JPG',
            '/storage/emulated/0/Download/gsmarena_045.jpeg',
            '/storage/emulated/0/Download/gsmarena_024.jpeg',
            '/storage/emulated/0/Download/gsmarena_022.jpeg',
            '/storage/emulated/0/Download/20220924_17560.jpg'
          ];

          localImageProvider =
              LocalImageProvider(photoPaths: photoPaths, initialIndex: 0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(1),
        itemCount: photoPaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: ((context, index) {
          return Container(
            padding: const EdgeInsets.all(0.5),
            child: InkWell(
              onTap: () => _openImage(index),
              child: Image.file(File(photoPaths[index])),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
