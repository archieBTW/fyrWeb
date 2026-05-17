import sys

with open('lib/apps/resume_app.dart', 'r') as f:
    content = f.read()

start_idx = content.find('  Future<void> _generatePdf(AppConfig config) async {')
end_idx = content.find('  @override\n  Widget build(BuildContext context) {')

if start_idx == -1 or end_idx == -1:
    print("Could not find bounds")
    sys.exit(1)

new_code = """  Future<void> _generatePdf(AppConfig config) async {
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
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          config.profile.name.toUpperCase(),
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
                          style: pw.TextStyle(color: primaryColor, fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      if (config.profile.location.isNotEmpty) ...[
                        pw.Text(
                          config.profile.location,
                          style: pw.TextStyle(color: primaryColor, fontSize: 12),
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
                      ...config.experience.map((e) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                e.role,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black),
                              ),
                              pw.Text(
                                e.period,
                                style: pw.TextStyle(color: primaryColor, fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            e.company,
                            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700, fontSize: 11),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            e.description,
                            style: pw.TextStyle(fontSize: 11, color: textColor, lineSpacing: 1.5),
                          ),
                          pw.SizedBox(height: 20),
                        ],
                      )).toList(),
                      
                      pw.SizedBox(height: 10),
                      _buildSectionHeader('EDUCATION', primaryColor),
                      ...config.education.map((e) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                e.school,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                              ),
                              pw.Text(
                                e.period,
                                style: pw.TextStyle(color: primaryColor, fontSize: 11),
                              ),
                            ],
                          ),
                          if (e.degree.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              e.degree,
                              style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700, fontSize: 11),
                            ),
                          ],
                          pw.SizedBox(height: 16),
                        ],
                      )).toList(),
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
                      ...config.skills.map((skillGroup) => pw.Column(
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
                            children: skillGroup.items.map((s) => pw.Text(
                              s, 
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)
                            )).toList(),
                          ),
                          pw.SizedBox(height: 16),
                        ],
                      )).toList(),
                      
                      if (config.certifications.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        _buildSectionHeader('CERTIFICATIONS', primaryColor),
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: config.certifications.map((c) => pw.Text(
                            c, 
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)
                          )).toList(),
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
    final filename = '${config.profile.name.toLowerCase().replaceAll(' ', '_')}_resume.pdf';

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
        pw.Container(
          height: 2,
          width: 30,
          color: color,
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

"""

with open('lib/apps/resume_app.dart', 'w') as f:
    f.write(content[:start_idx] + new_code + content[end_idx:])

print("Updated resume successfully")
