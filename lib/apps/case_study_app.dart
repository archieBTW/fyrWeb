import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/config_model.dart';

class CaseStudyApp extends StatelessWidget {
  final CustomApp app;

  const CaseStudyApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cases_rounded, color: Color(int.parse(app.color)), size: 40),
              const SizedBox(width: 16),
              Text(
                '${app.title}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: app.caseStudy?.length ?? 0,
              itemBuilder: (context, index) {
                final point = app.caseStudy![index];
                final parts = point.split(':');
                if (parts.length > 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.white, fontSize: 18)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, height: 1.5),
                              children: [
                                TextSpan(
                                  text: parts[0] + ':',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                TextSpan(
                                  text: parts.sublist(1).join(':'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.white, fontSize: 18)),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                final Uri uri = Uri.parse(app.url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Try it now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(int.parse(app.color)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
