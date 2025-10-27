import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinician Dashboard')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/dashboard/dist/index.html'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return WebView(
              initialUrl: Uri.dataFromString(
                snapshot.data!,
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8'),
              ).toString(),
              javascriptMode: JavascriptMode.unrestricted,
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load dashboard.'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

