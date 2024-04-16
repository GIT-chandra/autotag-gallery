// import 'package:flutter/material.dart';
// import 'package:easy_image_viewer/easy_image_viewer.dart';
// import 'dart:io';


// class LocalImageProvider extends EasyImageProvider {

//   final List<String> photoPaths;
//   final int initialIndex;

//   LocalImageProvider({ required this.photoPaths, this.initialIndex = 0 });

//   @override
//   ImageProvider<Object> imageBuilder(BuildContext context, int index) {
//     String? localImagePath = photoPaths[index];
//     File? imageFile;

//     if (localImagePath != null) {
//       imageFile = File(localImagePath);
//     }

//     ImageProvider imageProvider = imageFile != null ? FileImage(imageFile) : AssetImage("assets/images/product_placeholder.jpg") as ImageProvider;

//     return imageProvider;
//   }

//   @override
//   int get imageCount => photoPaths.length;  
// }

// class PhotoViewPage extends StatefulWidget {
//   final List<String> photos;
//   final int index;

//   const PhotoViewPage({
//     Key? key,
//     required this.photos,
//     required this.index,
//   }) : super(key: key);

//   @override
//   State<PhotoViewPage> createState() => _PhotoViewPageState();
// }

// class _PhotoViewPageState extends State<PhotoViewPage> {
//   late final LocalImageProvider productsImageProvider;
//   @override
//   void initState() {
//     super.initState();
//     productsImageProvider = LocalImageProvider(photoPaths: widget.photos, initialIndex: widget.index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: showImageViewerPager(context, productsImageProvider, onPageChanged: (page) {
//   print("page changed to $page");
// }, onViewerDismissed: (page) {
//   print("dismissed while on page $page");
// });
//     );
//   }
// }