import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/config_model.dart';

class CaseStudyApp extends StatefulWidget {
  final CustomApp app;

  const CaseStudyApp({super.key, required this.app});

  @override
  State<CaseStudyApp> createState() => _CaseStudyAppState();
}

class _CaseStudyAppState extends State<CaseStudyApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final primaryColor = Color(int.parse(app.color));

    return Container(
      color: const Color(0xFF14171C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Non-Overflowing Header
          _buildHeader(app, primaryColor),

          // Tabs
          Container(
            color: const Color(0xFF181C23),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isCompact = width < 440;
                final bool isMedium = width >= 440 && width < 620;

                final String devLabel;
                final String devopsLabel;
                final String sysadminLabel;

                if (isCompact) {
                  devLabel = 'Dev';
                  devopsLabel = 'DevOps';
                  sysadminLabel = 'SysAdmin';
                } else if (isMedium) {
                  devLabel = 'Software Dev';
                  devopsLabel = 'DevOps';
                  sysadminLabel = 'SysAdmin';
                } else {
                  devLabel = 'Software Architecture';
                  devopsLabel = 'DevOps & CI/CD';
                  sysadminLabel = 'SysAdmin & Security';
                }

                return TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3.0,
                  labelStyle: GoogleFonts.inter(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.code, size: isCompact ? 14 : 16),
                            SizedBox(width: isCompact ? 4 : 6),
                            Text(devLabel),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_sync_outlined,
                              size: isCompact ? 14 : 16,
                            ),
                            SizedBox(width: isCompact ? 4 : 6),
                            Text(devopsLabel),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: isCompact ? 14 : 16,
                            ),
                            SizedBox(width: isCompact ? 4 : 6),
                            Text(sysadminLabel),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPointList(
                  app.caseStudy,
                  'Application Engineering Highlights',
                  Icons.developer_mode,
                  primaryColor,
                ),
                _buildDevOpsTab(app, primaryColor),
                _buildSysAdminTab(app, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointList(
    List<String>? points,
    String sectionTitle,
    IconData icon,
    Color accentColor,
  ) {
    if (points == null || points.isEmpty) {
      return Center(
        child: Text(
          'No specific points recorded.',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 24.0,
            vertical: 18.0,
          ),
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 15 : 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...points.map((point) => _buildPointCard(point, accentColor)),
          ],
        );
      },
    );
  }

  Widget _buildDevOpsTab(CustomApp app, Color accentColor) {
    final devopsPoints =
        app.devopsStudy ??
        [
          'Terraform Infrastructure: Provisioned compute resources on Google Cloud Platform with automated Cloudflare DNS A-record mapping.',
          'Ansible Automation: Continuous configuration management and automated site distribution orchestrated via WE-IAC repository.',
          'Reverse Proxy & Rate Limiting: Nginx leaky-bucket traffic zones configured for 30 requests/second static burst protection.',
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 24.0,
            vertical: 18.0,
          ),
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Infrastructure as Code & Deployment Pipeline',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 15 : 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Deployment Command Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E232B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.terminal,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Deployment Orchestration (WE-IAC):',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          'ansible-playbook -i inventory.ini deploy-sites.yml -e site=${app.id}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.terminal,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deployment Orchestration (WE-IAC):',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            'ansible-playbook -i inventory.ini deploy-sites.yml -e site=${app.id}',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.greenAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Points
            ...devopsPoints.map((point) => _buildPointCard(point, accentColor)),
          ],
        );
      },
    );
  }

  Widget _buildSysAdminTab(CustomApp app, Color accentColor) {
    final sysadminPoints =
        app.sysadminStudy ??
        [
          'Host Firewall Hardening: Netfilter/UFW default DENY policy; rate-limited SSH (22) and production TLS (443) only.',
          'Intrusion Prevention: Fail2ban active jails monitoring sshd brute-force and nginx-limit-req with automated IP bans.',
          'Resource & Kernel Tuning: e2-micro host optimized with 2GB swap space, vm.swappiness=10, and adjusted vfs_cache_pressure.',
          'Zero-Trust Container Isolation: Database and internal APIs mapped strictly to isolated Docker bridge networks.',
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 24.0,
            vertical: 18.0,
          ),
          children: [
            Row(
              children: [
                Icon(Icons.security, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Host Hardening, Zero-Trust & Systems Administration',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 15 : 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SysAdmin Checklist Pill Matrix
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSecurityPill(
                  'TLS 1.3 Certbot Auto',
                  Icons.lock,
                  Colors.tealAccent,
                ),
                _buildSecurityPill(
                  'UFW Default DENY',
                  Icons.shield,
                  Colors.amberAccent,
                ),
                _buildSecurityPill(
                  'Fail2ban Multi-Jail',
                  Icons.gavel,
                  Colors.greenAccent,
                ),
                _buildSecurityPill(
                  'Zero Public DB Port',
                  Icons.visibility_off,
                  Colors.blueAccent,
                ),
                _buildSecurityPill(
                  '2GB Swap / 1GB RAM Tuning',
                  Icons.memory,
                  Colors.purpleAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Points
            ...sysadminPoints.map(
              (point) => _buildPointCard(point, accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityPill(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(String point, Color accentColor) {
    final parts = point.split(':');
    final hasPrefix = parts.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasPrefix
                ? RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '${parts[0]}: ',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(text: parts.sublist(1).join(':').trim()),
                      ],
                    ),
                  )
                : Text(
                    point,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CustomApp app, Color primaryColor) {
    final hasLiveUrl = app.url.isNotEmpty && !app.url.startsWith('internal://');
    final badgeItems = app.architectureBadge != null
        ? app.architectureBadge!
              .split('•')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    final badgeChips = badgeItems.map((badge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          badge,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F26),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.cases_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (app.subtitle != null &&
                              app.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              app.subtitle!,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasLiveUrl) ...[
                      const SizedBox(width: 10),
                      _buildLiveButton(primaryColor, compact: true),
                    ],
                  ],
                ),
                if (badgeChips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: badgeChips),
                ],
              ],
            );
          }

          // Wide / Desktop Window Header
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(Icons.cases_rounded, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          app.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...badgeChips,
                      ],
                    ),
                    if (app.subtitle != null && app.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        app.subtitle!,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasLiveUrl) ...[
                const SizedBox(width: 16),
                _buildLiveButton(primaryColor, compact: false),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLiveButton(Color primaryColor, {bool compact = false}) {
    return ElevatedButton.icon(
      onPressed: () async {
        final Uri uri = Uri.parse(widget.app.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: Icon(Icons.open_in_new, size: compact ? 14 : 16),
      label: const Text('Live Site'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 12,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}
