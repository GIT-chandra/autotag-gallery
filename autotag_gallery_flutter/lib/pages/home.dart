import 'dart:convert';

import 'package:autotag_gallery/pages/image_view.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as dart_path;
import 'dart:developer' as developer;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

const logName = 'com.etchandgear.garo';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double indexingFrac = 0.0;
  String indexingText = '';
  String indexingFileName = '';
  bool isIndexing = false;
  String rootPath = '';
  late Text titleWidget;

  List<String> photoPaths = [];
  List<bool> indexStat = [];

  final TextEditingController _searchTextController = TextEditingController();
  // final TextEditingController _dbNameTextController = TextEditingController();
  // final TextEditingController _apiAddrTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, Map<String, double>> globalScores = {};

  // late final SharedPreferences sharedPrefs;

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
          title: const Text('Search using Tags'),
          content: TextField(
            controller: _searchTextController,
            decoration: const InputDecoration(hintText: "Image Tag"),
          ),
          actions: <Widget>[
            MaterialButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            MaterialButton(
              child: const Text('Search'),
              onPressed: () {
                Navigator.pop(context);
                // return _runSearch(_searchTextController.text.toLowerCase());
                _runSearch(_searchTextController.text.toLowerCase());
              },
            ),
          ],
        );
      },
    );
  }

  void _openImage(int idx) {
    developer.log("opening image ${photoPaths[idx]}", name: logName);
    final name = dart_path.basename(photoPaths[idx]);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ImageViewPage(imgdata: ImageData(photoPaths[idx], name))));
  }

  @override
  void initState() {
    super.initState();
    titleWidget = Text(widget.title);
    _initializeLabeler();
    _loadImagesData(false);
  }

  void _initializeLabeler() async {
    // uncomment next line if you want to use the default model
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

    // NOTE: default model is slower but works better -
    //    has 400+ classes, which seems to be higher that the local file from plugin example

    // sharedPrefs = await SharedPreferences.getInstance();
  }

  late ImageLabeler _imageLabeler;

  Future<List<ImageLabel>> _processImage(int idx) async {
    try {
      final imgPath = photoPaths[idx];
      final labels =
          await _imageLabeler.processImage(InputImage.fromFilePath(imgPath));
      String text = 'Labels found: ${labels.length}\n\n';
      for (final label in labels) {
        text += 'Label: ${label.label}, '
            'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
      }
      developer.log('image: $imgPath, result: $text', name: logName);
      return labels;
    } catch (e) {
      developer.log(e.toString(), name: logName, level: 1);
      return [ImageLabel.fromJson({})];
    }
  }

  void _loadImagesData(bool runIndexing) async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted |
          await Permission.photos.request().isGranted) {
        final extDir = await getExternalStorageDirectory();
        developer.log((extDir?.path).toString(), name: logName);
        // /storage/emulated/0/Android/data/com.example.garo_flutter/files
        final storageRoot = extDir?.parent.parent.parent.parent;

        if (extDir != null && storageRoot != null) {
          final idxRootPath = dart_path.join(extDir.path, '.indices');

          rootPath = storageRoot.path;
          developer.log((rootPath).toString(), name: logName);

          photoPaths.clear();

          for (var ff in [
            // Directory(dart_path.join(rootPath, 'Pictures')),
            Directory(dart_path.join(rootPath, 'DCIM', 'Camera')),
            // Directory(dart_path.join(rootPath, 'Download'))
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

                  developer.log((filePath.path).toString(), name: logName);
                  photoPaths.add(filePath.path);

                  // if (mounted &&
                  //     imageCache.currentSizeBytes <
                  //         (imageCache.maximumSizeBytes - 1024 * 1024)) {
                  //   // precacheImage(
                  //   //     Image.file(File('some/path')) as ImageProvider, context,
                  //   //     size: const Size.fromWidth(192));
                  //   precacheImage(FileImage(File(filePath.path)), context);
                  //   developer.log("PRE-CACHING", name: logName);
                  // }
                }
              }
            }
          }

          // add indices wherever needed
          setState(() {
            isIndexing = true;
          });

          var indexedCount = 0;

          globalScores.clear();
          for (var photoPth in photoPaths) {
            setState(() {
              indexingFileName = photoPth;
            });
            try {
              final noRootPhotoPth = photoPth.substring(rootPath.length + 1);
              final touchPath = dart_path.join(idxRootPath, noRootPhotoPth);
              final touchFile = File(touchPath);
              if (touchFile.existsSync()) {
                final rawDataStr = touchFile.readAsStringSync();
                // developer.log("reading existing data - $rawDataStr",
                //     name: logName);

                final labelsData =
                    jsonDecode(rawDataStr) as Map<String, dynamic>;

                labelsData.forEach((key, value) {
                  final cleanKey = key.toLowerCase();
                  if (!globalScores.containsKey(cleanKey)) {
                    globalScores[cleanKey] = {};
                  }
                  globalScores[cleanKey]?[noRootPhotoPth] = value as double;
                });

                indexStat.add(true);
              } else if (runIndexing) {
                final idxPathDir = Directory(dart_path.dirname(touchPath));
                if (!idxPathDir.existsSync()) {
                  idxPathDir.createSync(recursive: true);
                }

                final labels = await _processImage(indexedCount);
                final Map<String, double> labelsData = {};
                for (final label in labels) {
                  labelsData[label.label] = label.confidence.toDouble();
                  // text += 'Label: ${label.label}, '
                  //     'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
                }
                touchFile.writeAsStringSync(jsonEncode(labelsData));

                indexStat.add(true);
              } else {
                indexStat.add(false);
              }

              setState(() {
                // localImageProvider.photoPaths.add(photoPaths[loadedCount]);
                indexedCount++;
                indexingFrac = indexedCount / photoPaths.length;
                indexingText =
                    'Indexing images - $indexedCount of ${photoPaths.length}';
                // developer.log("indexed $indexingFrac fraction of total images",
                //     name: logName);
              });
            } catch (e) {
              setState(() {
                indexingFileName = e.toString();
              });
            }
          }
          developer.log(globalScores.toString(), name: logName);
        }

        setState(() {
          isIndexing = false;
          indexingFrac = 0.0;
          indexingText = '';
        });
      }
    }
  }

  void _runSearch(String queryStr) async {
    developer.log(queryStr, name: logName);

    if (globalScores.containsKey(queryStr)) {
      // developer.log("GLobal data contains $queryStr !",
      //     name: logName);
      photoPaths.clear();
      final resultPaths = globalScores[queryStr]?.keys.toList() as List<String>;
      resultPaths.sort((b, a) => (globalScores[queryStr]?[a] as double)
          .compareTo(globalScores[queryStr]?[b] as double));
      // developer.log(resultPaths.toString(), name: logName);
      setState(() {
        titleWidget = Text('${resultPaths.length} results for "$queryStr"');
        for (final resPth in resultPaths) {
          photoPaths.add(dart_path.join(rootPath, resPth));
        }
      });
    } else {
      setState(() {
        titleWidget = Text('No results for "$queryStr"!');
        photoPaths.clear();
      });
      // return showDialog<void>(
      //   context: context,
      //   builder: (BuildContext context) {
      //     return AlertDialog(
      //       title: const Text('Not found'),
      //       content: Text(
      //         'No results found for tag "$queryStr"\n'
      //         'Please try with other tags.',
      //       ),
      //       actions: <Widget>[
      //         TextButton(
      //           style: TextButton.styleFrom(
      //             textStyle: Theme.of(context).textTheme.labelLarge,
      //           ),
      //           child: const Text('Close'),
      //           onPressed: () {
      //             Navigator.of(context).pop();
      //           },
      //         ),
      //       ],
      //     );
      //   },
      // );
    }
  }

  // void _
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
        title: titleWidget,
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
      bottomNavigationBar: isIndexing
          ? Container(
              constraints: BoxConstraints.tight(const Size.fromHeight(40)),
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.bottomCenter,
              child: Text(indexingFileName))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: () {
                      titleWidget = Text(widget.title);
                      _loadImagesData(true);
                    },
                    icon: const Icon(Icons.sync)),
                IconButton(
                    onPressed: () {
                      titleWidget = Text(widget.title);
                      _loadImagesData(false);
                      _scrollController.animateTo(
                          _scrollController.position.minScrollExtent,
                          duration: Durations.long1,
                          curve: Curves.fastOutSlowIn);
                    },
                    icon: const Icon(Icons.home)),
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
