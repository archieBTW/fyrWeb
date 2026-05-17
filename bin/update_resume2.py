import sys

with open('lib/apps/resume_app.dart', 'r') as f:
    content = f.read()

# 1. Remove toUpperCase() from name
content = content.replace('config.profile.name.toUpperCase(),', 'config.profile.name,')

# 2. Increase padding bottom for the header to add more space between name and content
content = content.replace('padding: const pw.EdgeInsets.only(bottom: 20),', 'padding: const pw.EdgeInsets.only(bottom: 40),')

# 3. Add 'PROFESSIONAL EXPERIENCE' before experience
exp_target = '...config.experience'
new_exp = """pw.Text(
                        'PROFESSIONAL EXPERIENCE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...config.experience"""
content = content.replace(exp_target, new_exp)

# 4. Replace EDUCATION header
edu_target = "_buildSectionHeader('EDUCATION', primaryColor),"
new_edu = """pw.Text(
                        'EDUCATION',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),"""
content = content.replace(edu_target, new_edu)

# 5. Replace CERTIFICATIONS header
cert_target = "_buildSectionHeader('CERTIFICATIONS', primaryColor),"
new_cert = """pw.Text(
                          'CERTIFICATIONS',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 12),"""
content = content.replace(cert_target, new_cert)

# Write back
with open('lib/apps/resume_app.dart', 'w') as f:
    f.write(content)

print("Updated resume formatting successfully")
