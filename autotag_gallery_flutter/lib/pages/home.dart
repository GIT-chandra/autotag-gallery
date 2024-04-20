import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as dart_path;
import 'dart:developer' as developer;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double indexingFrac = 0.0;
  String indexingText = '';
  bool isIndexing = false;
  String rootPath = '';

  List<String> photoPaths = [];
  List<bool> indexStat = [];

  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _searchTextController.dispose();
    super.dispose();
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Semantic Search'),
          content: TextField(
            controller: _searchTextController,
            decoration:
                const InputDecoration(hintText: "Description of the image"),
          ),
          actions: <Widget>[
            MaterialButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            MaterialButton(
              child: const Text('SEARCH'),
              onPressed: () {
                // _searchAPI(_searchTextController.text);
                developer.log(
                    "imageCache.liveImageCount ${imageCache.liveImageCount.toString()}",
                    name: 'com.etchandgear.garo');
                developer.log(
                    "imageCache.currentSizeBytes ${imageCache.currentSizeBytes.toString()}",
                    name: 'com.etchandgear.garo');
                developer.log(
                    "imageCache.maximumSizeBytes ${imageCache.maximumSizeBytes.toString()}",
                    name: 'com.etchandgear.garo');
                developer.log(
                    "imageCache.currentSize ${imageCache.currentSize.toString()}",
                    name: 'com.etchandgear.garo');
                developer.log(
                    "imageCache.maximumSize ${imageCache.maximumSize.toString()}",
                    name: 'com.etchandgear.garo');
                // _processImage(_searchTextController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateData() {
    _loadImagesData(true);
  }

  void _openImage(int idx) {
    developer.log("opening image ${photoPaths[idx]}",
        name: 'com.etchandgear.garo');
    // TODO
  }

  @override
  void initState() {
    super.initState();
    _initializeLabeler();
    _loadImagesData(false);
  }

  void _initializeLabeler() async {
    // uncomment next line if you want to use the default model
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

    // NOTE: default model is slower but works better -
    //    has 400+ classes, which seems to be higher that the local file from plugin example
  }

  late ImageLabeler _imageLabeler;

  Future<void> _processImage(String strIdx) async {
    final imgPath = photoPaths[int.parse(strIdx)];
    final labels =
        await _imageLabeler.processImage(InputImage.fromFilePath(imgPath));
    String text = 'Labels found: ${labels.length}\n\n';
    for (final label in labels) {
      text += 'Label: ${label.label}, '
          'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
    }
    developer.log('image: $imgPath, result: $text',
        name: 'com.etchandgear.garo');
  }

  void _loadImagesData(bool runIndexing) async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted |
          await Permission.photos.request().isGranted) {
        final extDir = await getExternalStorageDirectory();
        developer.log((extDir?.path).toString(), name: 'com.etchandgear.garo');
        // /storage/emulated/0/Android/data/com.example.garo_flutter/files
        final storageRoot = extDir?.parent.parent.parent.parent;

        if (extDir != null && storageRoot != null) {
          final idxRootPath = dart_path.join(extDir.path, '.indices');

          rootPath = storageRoot.path;
          developer.log((rootPath).toString(), name: 'com.etchandgear.garo');

          photoPaths.clear();

          for (var ff in [
            // Directory(dart_path.join(rootPath, 'Pictures')),
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

                  // if (mounted &&
                  //     imageCache.currentSizeBytes <
                  //         (imageCache.maximumSizeBytes - 1024 * 1024)) {
                  //   // precacheImage(
                  //   //     Image.file(File('some/path')) as ImageProvider, context,
                  //   //     size: const Size.fromWidth(192));
                  //   precacheImage(FileImage(File(filePath.path)), context);
                  //   developer.log("PRE-CACHING", name: 'com.etchandgear.garo');
                  // }
                }
              }
            }
          }

          // add indices wherever needed
          isIndexing = true;
          var indexedCount = 0;
          for (var photoPth in photoPaths) {
            if (runIndexing) {
              await _processImage(indexedCount.toString());
            }

            setState(() {
              // localImageProvider.photoPaths.add(photoPaths[loadedCount]);
              indexedCount++;
              indexingFrac = indexedCount / photoPaths.length;
              indexingText =
                  'Indexing images - $indexedCount of ${photoPaths.length}';
              developer.log("indexed $indexingFrac fraction of total images",
                  name: 'com.etchandgear.garo');
            });
          }
        }

        setState(() {
          isIndexing = false;
        });
      }
    }
  }

  void _searchAPI(String queryStr) async {
    developer.log(queryStr, name: 'com.etchandgear.garo');
  }

  @override
  Widget build(BuildContext context) {
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
      body: isIndexing
          ? Dialog(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      indexingText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: indexingFrac),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          : Scrollbar(
              thickness: 15.0,
              radius: const Radius.elliptical(4, 6),
              interactive: true,
              thumbVisibility: false,
              controller: _scrollController,
              child: GridView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(6),
                itemCount: photoPaths.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: ((context, index) {
                  return Card(
                    margin: const EdgeInsets.all(2.0),
                      child: InkWell(
                    onTap: () => _openImage(index),
                    child: index < photoPaths.length
                        ? Image.file(
                            File(photoPaths[index]),
                            fit: BoxFit.cover,
                            cacheWidth: 192,
                            isAntiAlias: true,
                          )
                        : Image.asset("assets/images/placeholder.png"),
                  ));
                }),
              ),
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _updateData,
      //   tooltip: 'Refresh',
      //   child: const Icon(Icons.sync),
      // ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(onPressed: _updateData, icon: const Icon(Icons.sync)),
          IconButton(
              onPressed: () {
                _searchTextController.clear();
                _displayTextInputDialog(context);
              },
              icon: const Icon(Icons.search)),
        ],
      ),
    );
  }
}
