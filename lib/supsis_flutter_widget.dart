library supsis_flutter_widget;

// lib/src/supsis_visitor_widget.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Utility function to get the domain URL
String getDomain(String? domainName, String environment) {
  String uri = "";
  if (environment == "beta") {
    uri = domainName != null
        ? "https://${domainName}.betavisitor.supsis.live/"
        : "https://betavisitor.supsis.live/";
  } else if (environment == "prod") {
    uri = domainName != null
        ? "https://${domainName}.visitor.supsis.live/"
        : "https://visitor.supsis.live/";
  }
  return uri;
}

// The controller class
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

// The SupsisVisitor widget
class SupsisVisitor extends StatefulWidget {
  final String? domainName;
  final String environment;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final SupsisVisitorController? controller;

  SupsisVisitor({
    Key? key,
    this.domainName,
    this.environment = 'prod',
    this.onConnected,
    this.onDisconnected,
    this.controller,
  }) : super(key: key ?? controller?._key);

  @override
  _SupsisVisitorState createState() => _SupsisVisitorState();
}

// The private state class
class _SupsisVisitorState extends State<SupsisVisitor> {
  late final WebViewController _webViewController;
  bool _visible = true;
  bool _loaded = false;
  final List<VoidCallback> _buff = [];
  bool _connected = false;

  String get uri => getDomain(widget.domainName, widget.environment);

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Flutter',
          onMessageReceived: _onJavascriptMessageReceived)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _onPageFinished(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(uri));
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
    if (mounted)
      setState(() {
        _visible = visible;
      });
  }

  void _onPageFinished(String url) {
    // Re-define window.postMessage
    _webViewController.runJavaScript('''
      window.postMessage = function(message) {
        Flutter.postMessage(JSON.stringify(message));
      };
    ''');
    _onLoadEnd();
  }

  void _onLoadEnd() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted)
        setState(() {
          _loaded = true;
        });
      if (_buff.isNotEmpty) {
        for (var fn in _buff) {
          fn();
        }
        _buff.clear();
      }
    });
  }

  void _onJavascriptMessageReceived(JavaScriptMessage message) {
    _listenPostMessage(message.message);
  }

  void _listenPostMessage(String message) {
    try {
      var data = jsonDecode(message);
      if (data['command'] == 'minimize') {
        _setVisible(false);
      } else if (data['command'] == 'visitor-connected') {
        if (!_connected) {
          widget.onConnected?.call();
        }
        _connected = true;
      } else if (data['command'] == 'visitor-disconnected') {
        if (_connected) {
          widget.onDisconnected?.call();
        }
        _connected = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing message: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _visible,
      child: SafeArea(
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
