import 'package:flutter/material.dart';

void registerIframe(String viewId, String url) {}

Widget buildHtmlView(String viewId) {
  return const Center(
    child: Text(
      'Browser view is only available on web',
      style: TextStyle(color: Colors.white70),
    ),
  );
}

