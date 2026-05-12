import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class BrowserApp extends StatefulWidget {
  final String url;
  const BrowserApp({super.key, required this.url});

  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'iframe-${widget.url.hashCode}';

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.black45,
          child: Row(
            children: [
              const Icon(Icons.lock, size: 14, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.url,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.refresh, size: 16, color: Colors.white54),
            ],
          ),
        ),
        // Content
        Expanded(child: HtmlElementView(viewType: _viewId)),
      ],
    );
  }
}
