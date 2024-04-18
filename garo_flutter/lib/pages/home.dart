import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as dart_path;
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

// 192.168.0.110:8000/

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
  // final apiDbName = 'garo_test_1';
  // final apiDbName = 'garo_test_android10';
  final apiDbName = 'garo_test_phone';
  double indexingFrac = 0.0;
  String indexingText = '';
  bool isIndexing = false;
  String rootPath = '';

  List<String> photoPaths = [];
  List<bool> indexStat = [];

  final TextEditingController _searchTextController = TextEditingController();

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
                _searchAPI(_searchTextController.text);
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
    _loadImagesData(false);
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

                  developer.log((filePath.path).toString(),
                      name: 'com.etchandgear.garo');
                  photoPaths.add(filePath.path);
                }
              }
            }
          }

          // add indices wherever needed
          isIndexing = true;
          var indexedCount = 0;
          for (var photoPth in photoPaths) {
            final noRootPhotoPth = photoPth.substring(rootPath.length + 1);
            final touchPath = dart_path.join(idxRootPath, noRootPhotoPth);
            if (File(touchPath).existsSync()) {
              indexStat.add(true);
            } else if (runIndexing) {
              final idxPathDir = Directory(dart_path.dirname(touchPath));
              if (!idxPathDir.existsSync()) {
                idxPathDir.createSync(recursive: true);
              }

              var url = Uri.http('192.168.0.110:8000', 'index/');
              // var response = await http
              //     .post(url, body: {'db_name': apiDbName, 'file_path': filePath});

              // thanks to https://stackoverflow.com/a/49378249, https://stackoverflow.com/a/57958447
              var request = http.MultipartRequest("POST", url);
              request.fields['db_name'] = apiDbName;
              request.fields['file_path'] = noRootPhotoPth;
              request.files
                  .add(await http.MultipartFile.fromPath('file', photoPth));
              var streamedResponse = await request.send();
              var response = await http.Response.fromStream(streamedResponse);
              developer.log('Response status: ${response.statusCode}',
                  name: 'com.etchandgear.garo');
              developer.log('Response body: ${response.body}',
                  name: 'com.etchandgear.garo');
              if (response.statusCode == 200) {
                File(touchPath).createSync();
                indexStat.add(true);
              } else {
                indexStat.add(false);
              }
            } else {
              indexStat.add(false);
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
    var url = Uri.http('192.168.0.110:8000', 'search/');

    var response = await http.post(url,
        body: jsonEncode({
          'db_name': apiDbName,
          'query_string': queryStr,
          // 'search_path': 'Download'
          'search_path': 'DCIM/Camera'
        }),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });

    // var request = http.MultipartRequest("POST", url);
    // request.fields['db_name'] = apiDbName;
    // request.fields['query_string'] = queryStr;
    // request.fields['search_path'] = 'Download';
    // var streamedResponse = await request.send();
    // var response = await http.Response.fromStream(streamedResponse);

    developer.log('Response status: ${response.statusCode}',
        name: 'com.etchandgear.garo');
    developer.log('Response body: ${response.body}',
        name: 'com.etchandgear.garo');
    // developer.log('search results: ${jsonDecode(response.body)['results']}',
    //     name: 'com.etchandgear.garo');
    photoPaths.clear();

    for (var resPth in jsonDecode(response.body)['results']) {
      developer.log(resPth, name: 'com.etchandgear.garo');
      photoPaths.add(dart_path.join(rootPath, resPth.toString()));
    }
    // photoPaths.addAll();
    if (response.statusCode == 200) {
      setState(() {});
    }
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
                    child: index < photoPaths.length
                        ? Image.file(
                            File(photoPaths[index]),
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            isAntiAlias: true,
                          )
                        : Image.asset("assets/images/placeholder.png"),
                  ),
                );
              }),
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
