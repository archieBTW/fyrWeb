import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

void registerIframe(String viewId, String url) {
  ui.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) => html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%',
  );
}

Widget buildHtmlView(String viewId) {
  return HtmlElementView(viewType: viewId);
}

