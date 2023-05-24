/* This is free and unencumbered software released into the public domain. */

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late InAppWebViewController? _controller;
  Uint8List? image;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            leading: image != null ? Image.memory(image!) : Container(),
            title: GestureDetector(
                onTap: () async {
                  print('tap');

                  image = await _controller?.takeScreenshot();
                  setState(() {});
                },
                child: Text("Model Viewer"))),
        body: ModelViewer(
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
          src: 'assets/Astronaut.glb',
          // a bundled asset file
          alt: "A 3D model of an astronaut",
          ar: true,
          arModes: ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          cameraControls: true,
          iosSrc: 'https://modelviewer.dev/shared-assets/models/Astronaut.usdz',
          disableZoom: true,
        ),
      ),
    );
  }
}
