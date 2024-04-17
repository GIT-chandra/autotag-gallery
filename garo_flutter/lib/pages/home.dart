import 'package:flutter/material.dart';
import 'dart:io';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as dart_path;
import 'dart:developer' as developer;
import 'package:image/image.dart' as img;

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
        : const AssetImage("assets/images/placeholder.png") as ImageProvider;

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
  double thumbLoadingFrac = 0.0;
  String thumbLoadingText = '';
  bool thumbLoading = false;

  List<String> photoPaths = [];
  List<String> thumbPaths = [];

  void _incrementCounter() {
    _getStoragePermission(true);
    // setState(() {
    //   _counter++;
    //   print("counter - " + _counter.toString());
    // });
  }

  void _openImage(int idx) {
    localImageProvider.initialIndex = idx;
    showImageViewerPager(context, localImageProvider, onPageChanged: (page) {
      print("page changed to $page");
    }, onViewerDismissed: (page) {
      print("dismissed while on page $page");
    }, doubleTapZoomable: false, swipeDismissible: false);
  }

  late final LocalImageProvider localImageProvider;
  @override
  void initState() {
    super.initState();
    localImageProvider =
        LocalImageProvider(photoPaths: photoPaths, initialIndex: 0);
    _getStoragePermission(false);
  }

  void _getStoragePermission(generateNewThumbnails) async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted |
          await Permission.photos.request().isGranted) {
        final extDir = await getExternalStorageDirectory();
        developer.log((extDir?.path).toString(), name: 'com.etchandgear.garo');
        // /storage/emulated/0/Android/data/com.example.garo_flutter/files
        final storageRoot = extDir?.parent.parent.parent.parent;

        if (extDir != null && storageRoot != null) {
          final thumbsRootPath = dart_path.join(extDir.path, '.thumbnails');

          final rootPath = storageRoot.path;
          developer.log((rootPath).toString(), name: 'com.etchandgear.garo');

          photoPaths.clear();
          thumbPaths.clear();

          for (var ff in [
            Directory(dart_path.join(rootPath, 'Pictures')),
            Directory(dart_path.join(rootPath, 'DCIM', 'Camera')),
            Directory(dart_path.join(rootPath, 'Download'))
          ]) {
            if (ff.existsSync()) {
              for (var filePath in ff.listSync(recursive: false)) {
                // print(filePath.path);
                if ([
                  '.jpg',
                  '.jpeg',
                  '.png'
                ].contains(dart_path.extension(filePath.path).toLowerCase())) {
                  // print("adding");

                  developer.log((filePath.path).toString(),
                      name: 'com.etchandgear.garo');
                  photoPaths.add(filePath.path);
                }
              }
            }
          }

          // create thumbnails, if needed
          thumbLoading = true;
          var loadedCount = 0;
          for (var photoPth in photoPaths) {
            final thumbPath = dart_path.join(
                thumbsRootPath, photoPth.substring(rootPath.length + 1));
            if (File(thumbPath).existsSync()) {
              thumbPaths.add(thumbPath);
            } else if (generateNewThumbnails){
              final thumbPathDir = Directory(dart_path.dirname(thumbPath));
              if (!thumbPathDir.existsSync()) {
                thumbPathDir.createSync(recursive: true);
              }

              final cmd = img.Command()
                // Decode the image file at the given path
                ..decodeImageFile(photoPth)
                // Resize the image to a width of 64 pixels and a height that maintains the aspect ratio of the original.
                ..copyResize(width: 128)
                // Write the image to a PNG file (determined by the suffix of the file path).
                ..writeToFile(thumbPath);
              // On platforms that support Isolates, execute the image commands asynchronously on an isolate thread.
              // Otherwise, the commands will be executed synchronously.
              await cmd.executeThread();
              thumbPaths.add(thumbPath);
            }

            setState(() {
              // localImageProvider.photoPaths.add(photoPaths[loadedCount]);
              loadedCount++;
              thumbLoadingFrac = loadedCount / photoPaths.length;
              thumbLoadingText =
                  'Generating thumbnails - $loadedCount of ${photoPaths.length}';
              developer.log("completed $thumbLoadingFrac fraction",
                  name: 'com.etchandgear.garo');
            });
          }
        }

        setState(() {
          thumbLoading = false;
          // photoPaths = [
          //   '/storage/emulated/0/DCIM/Camera/IMG_20240226_222211.jpg',
          //   '/storage/emulated/0/Download/20240313_185828.jpg',
          //   '/storage/emulated/0/Download/IMG_0011.JPG',
          //   '/storage/emulated/0/Download/IMG_0007.JPG',
          //   // '/storage/emulated/0/Download/IMG_0005.JPG',
          //   '/storage/emulated/0/Download/IMG_0001.JPG',
          //   '/storage/emulated/0/Download/gsmarena_045.jpeg',
          //   '/storage/emulated/0/Download/gsmarena_024.jpeg',
          //   '/storage/emulated/0/Download/gsmarena_022.jpeg',
          //   '/storage/emulated/0/Download/20220924_17560.jpg'
          // ];

          // localImageProvider =
          //     LocalImageProvider(photoPaths: photoPaths, initialIndex: 0);
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
      body: thumbLoading
          ? Dialog(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      thumbLoadingText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: thumbLoadingFrac),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
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
                    child: index < thumbPaths.length
                        ? Image.file(
                            File(thumbPaths[index]),
                            fit: BoxFit.cover,
                          )
                        : Image.asset("assets/images/placeholder.png"),
                  ),
                );
              }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Refresh',
        child: const Icon(Icons.sync),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
