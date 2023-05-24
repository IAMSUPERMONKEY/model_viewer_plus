/* This is free and unencumbered software released into the public domain. */

import 'dart:convert' show utf8;
import 'dart:io'
    show File, HttpRequest, HttpServer, HttpStatus, InternetAddress, Platform;

import 'package:android_intent_plus/android_intent.dart' as android_content;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'html_builder.dart';
import 'model_viewer_plus.dart';

class ModelViewerState extends State<ModelViewer> {
  late InAppWebViewController? _controller;

  HttpServer? _proxy;
  late String _proxyURL;

  InAppWebViewSettings settings = InAppWebViewSettings(
      cacheEnabled: false,
      clearCache: true,
      useOnLoadResource: true,
      transparentBackground: true,
      clearSessionCache: true,
      useHybridComposition: true,
      javaScriptEnabled: true,
      useShouldOverrideUrlLoading: true);

  @override
  void initState() {
    super.initState();
    _initProxy();
  }

  @override
  void dispose() {
    super.dispose();
    if (_proxy != null) {
      _proxy!.close(force: true);
      _proxy = null;
    }
  }

  @override
  void didUpdateWidget(final ModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO
  }

  @override
  Widget build(final BuildContext context) {
    if (_proxy == null) {
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Loading Model Viewer...',
        ),
      );
    } else {
      return InAppWebView(
        initialSettings: settings,
        onWebViewCreated: (controller) async {
          _controller = controller;

          widget.javascriptChannels?.forEach((element) {
            _controller!.addJavaScriptHandler(
              handlerName: element.name,
              callback: element.onMessageReceived,
            );
          });

          debugPrint('>>>> ModelViewer initializing... <$_proxyURL>'); // DEBUG
          widget.onWebViewCreated?.call(_controller!);
          await _controller!
              .loadUrl(urlRequest: URLRequest(url: WebUri(_proxyURL)));
        },
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        shouldOverrideUrlLoading: (InAppWebViewController controller,
            NavigationAction navigationAction) async {
          debugPrint(
              '>>>> ModelViewer wants to load: <${navigationAction.request}>'); // DEBUG
          if (!Platform.isAndroid) {
            if (Platform.isIOS &&
                navigationAction.request.url == widget.iosSrc) {
              // TODO: Migrate to launchUrl()
              await launch(
                navigationAction.request.url!.uriValue.toString(),
                forceSafariVC: true,
              );
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          }
          if (!navigationAction.request.url!.uriValue
              .toString()
              .startsWith("intent://")) {
            return NavigationActionPolicy.ALLOW;
          }
          try {
            // Original, just keep as a backup
            // See: https://developers.google.com/ar/develop/java/scene-viewer
            // final intent = android_content.AndroidIntent(
            //   action: "android.intent.action.VIEW", // Intent.ACTION_VIEW
            //   data: "https://arvr.google.com/scene-viewer/1.0",
            //   arguments: <String, dynamic>{
            //     'file': widget.src,
            //     'mode': 'ar_preferred',
            //   },
            //   package: "com.google.ar.core",
            //   flags: <int>[
            //     Flag.FLAG_ACTIVITY_NEW_TASK
            //   ], // Intent.FLAG_ACTIVITY_NEW_TASK,
            // );

            // 2022-03-14 update
            final String fileURL;
            if (['http', 'https'].contains(Uri.parse(widget.src).scheme)) {
              fileURL = widget.src;
            } else {
              fileURL = p.joinAll([_proxyURL, 'model']);
            }
            final intent = android_content.AndroidIntent(
              action: "android.intent.action.VIEW",
              // Intent.ACTION_VIEW
              // See https://developers.google.com/ar/develop/scene-viewer#3d-or-ar
              // data should be something like "https://arvr.google.com/scene-viewer/1.0?file=https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Avocado/glTF/Avocado.gltf"
              data: Uri(
                  scheme: 'https',
                  host: 'arvr.google.com',
                  path: '/scene-viewer/1.0',
                  queryParameters: {
                    // 'title': '', // TODO: maybe set by the user
                    // TODO: further test, and make it 'ar_preferred'
                    'mode': 'ar_preferred',
                    'file': fileURL,
                  }).toString(),
              // package changed to com.google.android.googlequicksearchbox
              // to support the widest possible range of devices
              package: "com.google.android.googlequicksearchbox",
              arguments: <String, dynamic>{
                'browser_fallback_url':
                    'market://details?id=com.google.android.googlequicksearchbox'
              },
            );
            await intent.launch().onError((error, stackTrace) {
              debugPrint('>>>> ModelViewer Intent Error: $error'); // DEBUG
            });
          } catch (error) {
            debugPrint('>>>> ModelViewer failed to launch AR: $error'); // DEBUG
          }
          return NavigationActionPolicy.CANCEL;
        },
      );
    }
  }

  String _buildHTML(final String htmlTemplate) {
    return HTMLBuilder.build(
      htmlTemplate: htmlTemplate,
      src: '/model',
      alt: widget.alt,
      poster: widget.poster,
      loading: widget.loading,
      reveal: widget.reveal,
      withCredentials: widget.withCredentials,
      // AR Attributes
      ar: widget.ar,
      arModes: widget.arModes,
      arScale: widget.arScale,
      arPlacement: widget.arPlacement,
      iosSrc: widget.iosSrc,
      xrEnvironment: widget.xrEnvironment,
      // Staing & Cameras Attributes
      cameraControls: widget.cameraControls,
      disablePan: widget.disablePan,
      disableTap: widget.disableTap,
      touchAction: widget.touchAction,
      disableZoom: widget.disableZoom,
      orbitSensitivity: widget.orbitSensitivity,
      autoRotate: widget.autoRotate,
      autoRotateDelay: widget.autoRotateDelay,
      rotationPerSecond: widget.rotationPerSecond,
      interactionPrompt: widget.interactionPrompt,
      interactionPromptStyle: widget.interactionPromptStyle,
      interactionPromptThreshold: widget.interactionPromptThreshold,
      cameraOrbit: widget.cameraOrbit,
      cameraTarget: widget.cameraTarget,
      fieldOfView: widget.fieldOfView,
      maxCameraOrbit: widget.maxCameraOrbit,
      minCameraOrbit: widget.minCameraOrbit,
      maxFieldOfView: widget.maxFieldOfView,
      minFieldOfView: widget.minFieldOfView,
      interpolationDecay: widget.interpolationDecay,
      // Lighting & Env Attributes
      skyboxImage: widget.skyboxImage,
      environmentImage: widget.environmentImage,
      exposure: widget.exposure,
      shadowIntensity: widget.shadowIntensity,
      shadowSoftness: widget.shadowSoftness,
      // Animation Attributes
      animationName: widget.animationName,
      animationCrossfadeDuration: widget.animationCrossfadeDuration,
      autoPlay: widget.autoPlay,
      // Materials & Scene Attributes
      variantName: widget.variantName,
      orientation: widget.orientation,
      scale: widget.scale,

      // CSS Styles
      backgroundColor: widget.backgroundColor,

      // Annotations CSS
      minHotspotOpacity: widget.minHotspotOpacity,
      maxHotspotOpacity: widget.maxHotspotOpacity,

      // Others
      innerModelViewerHtml: widget.innerModelViewerHtml,
      relatedCss: widget.relatedCss,
      relatedJs: widget.relatedJs,
      id: widget.id,
      debugLogging: widget.debugLogging,
    );
  }

  Future<void> _initProxy() async {
    final url = Uri.parse(widget.src);
    _proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    setState(() {
      _proxy;
      final host = _proxy!.address.address;
      final port = _proxy!.port;
      _proxyURL = "http://$host:$port/";
    });

    _proxy!.listen((final HttpRequest request) async {
      //debugPrint("${request.method} ${request.uri}"); // DEBUG
      //debugPrint(request.headers); // DEBUG
      final response = request.response;

      switch (request.uri.path) {
        case '/':
        case '/index.html':
          final htmlTemplate = await rootBundle
              .loadString('packages/model_viewer_plus/assets/template.html');
          final html = utf8.encode(_buildHTML(htmlTemplate));
          response
            ..statusCode = HttpStatus.ok
            ..headers.add("Content-Type", "text/html;charset=UTF-8")
            ..headers.add("Content-Length", html.length.toString())
            ..add(html);
          await response.close();
          break;

        case '/model-viewer.min.js':
          final code = await _readAsset(
              'packages/model_viewer_plus/assets/model-viewer.min.js');
          response
            ..statusCode = HttpStatus.ok
            ..headers
                .add("Content-Type", "application/javascript;charset=UTF-8")
            ..headers.add("Content-Length", code.lengthInBytes.toString())
            ..add(code);
          await response.close();
          break;

        case '/model':
          if (url.isAbsolute && !url.isScheme("file")) {
            // debugPrint(url.toString());
            await response.redirect(url); // TODO: proxy the resource
          } else {
            final data = await (url.isScheme("file")
                ? _readFile(url.path)
                : _readAsset(url.path));
            response
              ..statusCode = HttpStatus.ok
              ..headers.add("Content-Type", "application/octet-stream")
              ..headers.add("Content-Length", data.lengthInBytes.toString())
              ..headers.add("Access-Control-Allow-Origin", "*")
              ..add(data);
            await response.close();
          }
          break;

        case '/favicon.ico':
          final text = utf8.encode("Resource '${request.uri}' not found");
          response
            ..statusCode = HttpStatus.notFound
            ..headers.add("Content-Type", "text/plain;charset=UTF-8")
            ..headers.add("Content-Length", text.length.toString())
            ..add(text);
          await response.close();
          break;

        default:
          if (request.uri.isAbsolute) {
            debugPrint("Redirect: ${request.uri}");
            await response.redirect(request.uri);
          } else if (request.uri.hasAbsolutePath) {
            // Some gltf models need other resources from the origin
            var pathSegments = [...url.pathSegments];
            pathSegments.removeLast();
            var tryDestination = p.joinAll([
              url.origin,
              ...pathSegments,
              request.uri.path.replaceFirst('/', '')
            ]);
            debugPrint("Try: $tryDestination");
            await response.redirect(Uri.parse(tryDestination));
          } else {
            debugPrint('404 with ${request.uri}');
            final text = utf8.encode("Resource '${request.uri}' not found");
            response
              ..statusCode = HttpStatus.notFound
              ..headers.add("Content-Type", "text/plain;charset=UTF-8")
              ..headers.add("Content-Length", text.length.toString())
              ..add(text);
            await response.close();
            break;
          }
      }
    });
  }

  Future<Uint8List> _readAsset(final String key) async {
    final data = await rootBundle.load(key);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List> _readFile(final String path) async {
    return await File(path).readAsBytes();
  }
}
