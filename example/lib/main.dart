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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _App(),
    );
  }
}

class _App extends StatefulWidget {
  const _App({Key? key}) : super(key: key);

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late InAppWebViewController? _controller;
  Uint8List? image;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: image != null ? Image.memory(image!) : Container(),
        title: GestureDetector(
          onTap: () async {
            print('tap');

            image = await _controller?.takeScreenshot();
            setState(() {});
          },
          child: Text("Model Viewer"),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _Page(),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(80),
        child: ModelViewer(
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          src: 'assets/Astronaut.glb',
          // a bundled asset file
          alt: "A 3D model of an astronaut",
          ar: true,
          arModes: ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          cameraControls: true,
          iosSrc: 'https://modelviewer.dev/shared-assets/models/Astronaut.usdz',
          disableZoom: true,
          relatedCss: '''
            * {  
  -webkit-touch-callout:none;  
  -webkit-user-select:none;  
  -khtml-user-select:none;  
  -moz-user-select:none;  
  -ms-user-select:none;  
  user-select:none;  
} 
html, body,model-viewer {  
    -webkit-touch-callout:none;  
    -webkit-user-select:none;  
    -khtml-user-select:none;  
    -moz-user-select:none;  
    -ms-user-select:none;  
    user-select:none;  
} 
            ''',
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Model Viewer")),
      body: ModelViewer(
        id: "shoe",
        src: 'https://modelviewer.dev/shared-assets/models/shishkebab.glb',
        alt: "A 3D model of a Shoe",
        ar: true,
        cameraControls: true,
      ),
    );
  }
}
