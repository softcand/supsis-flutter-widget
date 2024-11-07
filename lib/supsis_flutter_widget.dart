import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

String getDomain(String? domainName, String environment) {
  if (environment == "beta") {
    return domainName != null
        ? "https://${domainName}.betavisitor.supsis.live/"
        : "https://betavisitor.supsis.live/";
  } else if (environment == "prod") {
    return domainName != null
        ? "https://${domainName}.visitor.supsis.live/"
        : "https://visitor.supsis.live/";
  }
  return "https://visitor.supsis.live/";
}

class SupsisVisitorController {
  final GlobalKey<_SupsisVisitorState> _key = GlobalKey<_SupsisVisitorState>();

  void setContactProperty(Map<String, dynamic> payload) {
    _key.currentState?._setContactProperty(payload);
  }

  void setUserData(Map<String, dynamic> payload) {
    _key.currentState?._setUserData(payload);
  }

  void setDepartment(String payload) {
    _key.currentState?._setDepartment(payload);
  }

  void autoLogin(Map<String, dynamic> payload) {
    _key.currentState?._autoLogin(payload);
  }

  void clearCache() {
    _key.currentState?._clearCache();
  }

  void open() {
    _key.currentState?._setVisible(true);
  }

  void close() {
    _key.currentState?._setVisible(false);
  }
}

class SupsisVisitor extends StatefulWidget {
  final String? domainName;
  final String environment;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final SupsisVisitorController? controller;
  final VoidCallback? onMinimized;
  final Color linearProgressColor;
  final Color circularProgressColor;

  SupsisVisitor({
    Key? key,
    this.domainName,
    this.environment = 'prod',
    this.onConnected,
    this.onDisconnected,
    this.controller,
    this.onMinimized,
    this.linearProgressColor = Colors.black,
    this.circularProgressColor = Colors.white,
  }) : super(key: key ?? controller?._key);

  @override
  _SupsisVisitorState createState() => _SupsisVisitorState();
}

class _SupsisVisitorState extends State<SupsisVisitor>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _webViewController;
  bool _visible = true;
  bool _loaded = false;
  final List<VoidCallback> _buff = [];
  bool _connected = false;
  double _progress = 0;

  String get uri => getDomain(widget.domainName, widget.environment);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print("Initializing WebView with URL: $uri");
    _initializeWebViewController();
  }

  void _initializeWebViewController() async {
    print("Setting up WebViewController...");

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          _listenPostMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            print("Navigating to: ${request.url}");
            return request.url.startsWith(uri)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            print("Page loaded: $url");
            _onLoadEnd();
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print("WebView Error: ${error.errorCode} - ${error.description}");
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(uri));

    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  void _inject(String cmd, dynamic payload) {
    String script = '''
    window.postMessage({
      command: "$cmd",
      payload: $payload,
    });
    ''';
    _webViewController.runJavaScript(script);
  }

  void _add2Buff(VoidCallback fn) {
    _buff.add(fn);
  }

  void _setContactProperty(Map<String, dynamic> payload) {
    VoidCallback fn =
        () => _inject("set-contact-property", jsonEncode(payload));
    if (_loaded) {
      fn();
    } else {
      _add2Buff(fn);
    }
  }

  void _setUserData(Map<String, dynamic> payload) {
    VoidCallback fn = () => _inject("set-user-data", jsonEncode(payload));
    if (_loaded) {
      fn();
    } else {
      _add2Buff(fn);
    }
  }

  void _setDepartment(String payload) {
    VoidCallback fn = () => _inject("set-department", jsonEncode(payload));
    if (_loaded) {
      fn();
    } else {
      _add2Buff(fn);
    }
  }

  void _autoLogin(Map<String, dynamic> payload) {
    var body = {'initialMessage': '', 'loginData': payload};
    VoidCallback fn = () => _inject("auto-login", jsonEncode(body));
    if (_loaded) {
      fn();
    } else {
      _add2Buff(fn);
    }
  }

  void _clearCache() {
    VoidCallback fn = () => _inject("auto-login", jsonEncode({}));
    if (_loaded) {
      fn();
    } else {
      _add2Buff(fn);
    }
  }

  void _setVisible(bool visible) {
    if (mounted) {
      setState(() {
        _visible = visible;
      });
    }
  }

  void _onLoadEnd() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _loaded = true;
          _progress = 1.0;
        });
        for (var fn in _buff) {
          fn();
        }
        _buff.clear();
      }
    });
  }

  void _listenPostMessage(String message) {
    try {
      var data = jsonDecode(message);
      switch (data['command']) {
        case 'minimize':
          _setVisible(false);
          widget.onMinimized?.call();
          break;
        case 'visitor-connected':
          if (!_connected) widget.onConnected?.call();
          _connected = true;
          break;
        case 'visitor-disconnected':
          if (_connected) widget.onDisconnected?.call();
          _connected = false;
          break;
      }
    } catch (e) {
      if (kDebugMode) print("Error parsing message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Visibility(
      visible: _visible,
      child: SafeArea(
        child: Stack(
          children: [
            _loaded
                ? WebViewWidget(controller: _webViewController)
                : SizedBox.shrink(),
            if (_progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade300,
                color: widget.linearProgressColor,
              ),
            if (!_loaded)
              Center(
                child: CircularProgressIndicator(
                    color: widget.circularProgressColor),
              ),
          ],
        ),
      ),
    );
  }
}
