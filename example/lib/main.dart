import 'package:flutter/material.dart';
import 'package:supsis_flutter_widget/supsis_flutter_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupsisVisitorController _controller = SupsisVisitorController();

  @override
  void initState() {
    super.initState();

    // Automatically set user data when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.setUserData({
        'name': 'John Doe',
        'email': 'john.doe@example.com',
      });
      print('User data set in initState.');

      _controller.setContactProperty({
        'phone': '1234567890',
        'address': '123 Main Street',
      });
      print('Contact property set in initState.');
    });
  }

  // Define the clearCache function, but don't use it initially
  void clearCache() {
    _controller.clearCache();
    print('Cache cleared.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SupsisVisitor(
          controller: _controller,
          domainName: 'butikponcik',
          environment: 'prod', // or 'beta'
          onConnected: () {
            print('Visitor connected');
          },
          onDisconnected: () {
            print('Visitor disconnected');
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 64.0, right: 16),
          child: FloatingActionButton(
            onPressed: () {
              _controller.open();
              print('WebView opened.');
            },
            child: Icon(Icons.visibility),
          ),
        ),
      ),
    );
  }
}
