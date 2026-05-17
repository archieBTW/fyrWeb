import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import '../models/config_model.dart';

class ResumeApp extends StatelessWidget {
  const ResumeApp({super.key});

  Future<void> _generatePdf(AppConfig config) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final italicFont = await PdfGoogleFonts.interItalic();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
    );

    final primaryColor = PdfColor.fromHex('#4B0082'); // Indigo/Deep Purple
    final textColor = PdfColors.grey800;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
        ),
        build: (pw.Context context) {
          return [
            // Header Section (no background color)
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 40),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          config.profile.name,
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          config.profile.title,
                          style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (config.profile.email.isNotEmpty) ...[
                        pw.Text(
                          config.profile.email,
                          style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      if (config.profile.location.isNotEmpty) ...[
                        pw.Text(
                          config.profile.location,
                          style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text(
                        'github.com/archieBTW',
                        style: pw.TextStyle(color: primaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body Content
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column: Experience & Education
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROFESSIONAL EXPERIENCE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...config.experience
                          .map(
                            (e) => pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  e.role,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11,
                                    color: PdfColors.black,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      e.company,
                                      style: pw.TextStyle(
                                        fontStyle: pw.FontStyle.italic,
                                        color: PdfColors.grey700,
                                        fontSize: 11,
                                      ),
                                    ),
                                    pw.Text(
                                      e.period,
                                      style: pw.TextStyle(
                                        color: primaryColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  e.description,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: textColor,
                                    lineSpacing: 1.5,
                                  ),
                                ),
                                pw.SizedBox(height: 20),
                              ],
                            ),
                          )
                          .toList(),

                      pw.SizedBox(height: 10),
                      pw.Text(
                        'EDUCATION',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...config.education
                          .map(
                            (e) => pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      e.school,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    pw.Text(
                                      e.period,
                                      style: pw.TextStyle(
                                        color: primaryColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (e.degree.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    e.degree,
                                    style: pw.TextStyle(
                                      fontStyle: pw.FontStyle.italic,
                                      color: PdfColors.grey700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                pw.SizedBox(height: 16),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),

                pw.SizedBox(width: 40),

                // Right Column: Skills & Certifications
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...config.skills
                          .map(
                            (skillGroup) => pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  skillGroup.category.toUpperCase(),
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: skillGroup.items
                                      .map(
                                        (s) => pw.Text(
                                          s,
                                          style: pw.TextStyle(
                                            fontSize: 10,
                                            color: PdfColors.grey800,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                pw.SizedBox(height: 16),
                              ],
                            ),
                          )
                          .toList(),

                      if (config.certifications.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'CERTIFICATIONS',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: config.certifications
                              .map(
                                (c) => pw.Text(
                                  c,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final filename =
        '${config.profile.name.toLowerCase().replaceAll(' ', '_')}_resume.pdf';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 30, color: color),
        pw.SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();

    final List<Color> categoryColors = [
      const Color(0xFFE6E6FA), // Lavender
      const Color(0xFFD4F1F4), // Soft Blue
      const Color(0xFFE2F0CB), // Soft Green
      const Color(0xFFFFDAB9), // Soft Orange
      const Color(0xFFFDE8E9), // Soft Pink
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generatePdf(config),
        tooltip: 'Download PDF',
        child: const Icon(Icons.picture_as_pdf),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(config.profile.profilePic),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.profile.name,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        config.profile.title,
                        style: GoogleFonts.inter(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _Section(
              title: 'Experience',
              children: config.experience
                  .map(
                    (item) => _ExperienceItem(
                      company: item.company,
                      role: item.role,
                      period: item.period,
                      description: item.description,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            if (config.education.isNotEmpty) ...[
              _Section(
                title: 'Education',
                children: config.education
                    .map(
                      (item) => _EducationItem(
                        school: item.school,
                        degree: item.degree,
                        period: item.period,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
            if (config.certifications.isNotEmpty) ...[
              _Section(
                title: 'Certifications',
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: config.certifications
                        .map(
                          (cert) => _SkillChip(
                            label: cert,
                            outlineColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            _Section(
              title: 'Skills',
              children: config.skills.asMap().entries.map((entry) {
                final index = entry.key;
                final skillGroup = entry.value;
                final color = categoryColors[index % categoryColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skillGroup.category,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skillGroup.items
                            .map(
                              (skill) =>
                                  _SkillChip(label: skill, outlineColor: color),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Divider(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          height: 24,
        ),
        ...children,
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final String company;
  final String role;
  final String period;
  final String description;

  const _ExperienceItem({
    required this.company,
    required this.role,
    required this.period,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  role,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                period,
                style: GoogleFonts.inter(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            company,
            style: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final Color outlineColor;

  const _SkillChip({
    required this.label,
    this.outlineColor = const Color.fromARGB(255, 114, 64, 127),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.fromARGB(255, 114, 64, 127),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final String school;
  final String degree;
  final String period;

  const _EducationItem({
    required this.school,
    required this.degree,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  school,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                period,
                style: GoogleFonts.inter(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (degree.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              degree,
              style: GoogleFonts.inter(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
