import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfraMonitorApp extends StatefulWidget {
  const InfraMonitorApp({super.key});

  @override
  State<InfraMonitorApp> createState() => _InfraMonitorAppState();
}

class _InfraMonitorAppState extends State<InfraMonitorApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProbing = false;

  final List<Map<String, dynamic>> _endpoints = [
    {
      'domain': 'archerwoods.dev',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 32,
      'status': 200,
    },
    {
      'domain': 'friendly.archerwoods.dev',
      'type': 'Blazor WASM SPA',
      'rateLimit': '30 r/s',
      'latency': 34,
      'status': 200,
    },
    {
      'domain': 'api.friendly.archerwoods.dev',
      'type': 'Spring Boot Proxy (:8070)',
      'rateLimit': '20 r/s',
      'latency': 29,
      'status': 200,
    },
    {
      'domain': 'bybl.dev',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 41,
      'status': 200,
    },
    {
      'domain': 'api.bybl.dev',
      'type': 'Go REST Proxy (:8080)',
      'rateLimit': '20 r/s',
      'latency': 28,
      'status': 200,
    },
    {
      'domain': 'gofyr.bybl.dev',
      'type': 'Go Admin Proxy (:8081)',
      'rateLimit': '20 r/s',
      'latency': 35,
      'status': 200,
    },
    {
      'domain': 'archbtw.sh',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 38,
      'status': 200,
    },
    {
      'domain': 'libretrac.site',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 44,
      'status': 200,
    },
    {
      'domain': 'theolivebranch.press',
      'type': 'Static + RSS Proxy',
      'rateLimit': '30 r/s',
      'latency': 48,
      'status': 200,
    },
    {
      'domain': 'carlyleauto.online',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 39,
      'status': 200,
    },
    {
      'domain': 'welledumacated.dev',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 42,
      'status': 200,
    },
    {
      'domain': 'fyr.software',
      'type': 'Static Flutter Web',
      'rateLimit': '30 r/s',
      'latency': 46,
      'status': 200,
    },
    {
      'domain': 'beats.archerwoods.dev',
      'type': 'Static Flutter Web',
      'rateLimit': '50 r/s',
      'latency': 34,
      'status': 200,
    },
  ];

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

  void _probeEndpoints() {
    if (_isProbing) return;
    setState(() => _isProbing = true);

    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final rng = Random();
      setState(() {
        for (var ep in _endpoints) {
          ep['latency'] = 22 + rng.nextInt(35);
        }
        _isProbing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14171C),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildServicesTab(),
                _buildNetworkAndSecurityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F26),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final probeButton = OutlinedButton.icon(
            onPressed: _isProbing ? null : _probeEndpoints,
            icon: _isProbing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00B0FF),
                    ),
                  )
                : const Icon(Icons.refresh, size: 15),
            label: Text(
              _isProbing ? 'Probing...' : (isNarrow ? 'Probe' : 'Probe Live'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00B0FF),
              side: const BorderSide(color: Color(0xFF00B0FF)),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 10 : 12,
                vertical: isNarrow ? 6 : 8,
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: Color(0xFF00B0FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'gcp-production-us-central1',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              'HEALTHY',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.greenAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    probeButton,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Debian 12 • GCP e2-micro • Terraform & Ansible Managed',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: Color(0xFF00B0FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'gcp-production-us-central1',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'HEALTHY',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Debian GNU/Linux 12 (Bookworm) • Linux 5.15.0-generic • GCP e2-micro • Terraform & Ansible Managed',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              probeButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF181C23),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 440;
          final isMedium = width >= 440 && width < 620;

          final String telemetryLabel;
          final String servicesLabel;
          final String zeroTrustLabel;

          if (isCompact) {
            telemetryLabel = 'Telemetry';
            servicesLabel = 'Services';
            zeroTrustLabel = 'Zero-Trust';
          } else if (isMedium) {
            telemetryLabel = 'Telemetry & RAM';
            servicesLabel = 'Services';
            zeroTrustLabel = 'Zero-Trust & Net';
          } else {
            telemetryLabel = 'Telemetry & Resources';
            servicesLabel = 'Services & Containers';
            zeroTrustLabel = 'Zero-Trust & Endpoints';
          }

          return TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: const Color(0xFF00B0FF),
            unselectedLabelColor: Colors.white60,
            indicatorColor: const Color(0xFF00B0FF),
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
                      Icon(Icons.speed, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 6),
                      Text(telemetryLabel),
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
                      Icon(Icons.layers, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 6),
                      Text(servicesLabel),
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
                      Icon(Icons.shield_outlined, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 6),
                      Text(zeroTrustLabel),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        final horizontalPadding = isNarrow ? 14.0 : 20.0;

        final cpuCard = _buildMetricCard(
          title: 'CPU UTILIZATION',
          value: '14.2%',
          detail: '2 vCPUs (GCP e2-micro)',
          subdetail: 'Load: 0.18, 0.22, 0.19',
          percent: 0.142,
          color: Colors.blueAccent,
          icon: Icons.memory,
        );

        final ramCard = _buildMetricCard(
          title: 'PHYSICAL RAM',
          value: '718 MB / 1024 MB',
          detail: '70% Allocated',
          subdetail: 'Free: 306 MB | Buffers: 84 MB',
          percent: 0.70,
          color: Colors.amberAccent,
          icon: Icons.storage,
        );

        final swapCard = _buildMetricCard(
          title: 'SWAP MEMORY (SysAdmin)',
          value: '224 MB / 2048 MB',
          detail: 'Tuned: vm.swappiness=20',
          subdetail: 'OOM Prevention on 1GB RAM',
          percent: 0.11,
          color: Colors.tealAccent,
          icon: Icons.cached,
        );

        final diskCard = _buildMetricCard(
          title: 'PERSISTENT DISK',
          value: '8.4 GB / 20.0 GB',
          detail: 'pd-balanced rootfs',
          subdetail: '11.6 GB available (42%)',
          percent: 0.42,
          color: Colors.purpleAccent,
          icon: Icons.disc_full,
        );

        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            // Resource Meters
            if (isNarrow)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cpuCard),
                      const SizedBox(width: 10),
                      Expanded(child: ramCard),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: swapCard),
                      const SizedBox(width: 10),
                      Expanded(child: diskCard),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: cpuCard),
                  const SizedBox(width: 12),
                  Expanded(child: ramCard),
                  const SizedBox(width: 12),
                  Expanded(child: swapCard),
                  const SizedBox(width: 12),
                  Expanded(child: diskCard),
                ],
              ),
            const SizedBox(height: 20),

            // SysAdmin Optimization Highlights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: Color(0xFF00B0FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SysAdmin Kernel & Memory Optimization Matrix',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildSysctlTag(
                        'vm.swappiness = 20',
                        'Prioritize RAM, prevent aggressive swapping (roles/common)',
                      ),
                      _buildSysctlTag(
                        'vm.vfs_cache_pressure = 50',
                        'Retain inode/dentry caches for disk I/O performance',
                      ),
                      _buildSysctlTag(
                        'net.ipv4.tcp_syncookies = 1',
                        'SYN flood denial-of-service kernel protection',
                      ),
                      _buildSysctlTag(
                        'net.ipv4.conf.all.rp_filter = 1',
                        'Strict reverse path filtering IP spoofing protection',
                      ),
                      _buildSysctlTag(
                        'net.ipv4.conf.all.accept_source_route = 0',
                        'Disable malicious packet source routing',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Endpoints Summary
            Text(
              'Managed Hosted Services (WE-IAC Topology)',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            _buildEndpointsTable(),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String detail,
    required String subdetail,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subdetail,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white38,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSysctlTag(String cmd, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF232A34),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cmd,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final services = [
      {
        'name': 'nginx.service',
        'type': 'systemd unit',
        'status': 'active (running)',
        'description':
            'Reverse proxy, TLS 1.3 termination, leaky-bucket rate limiting',
        'ports': '80/tcp, 443/tcp',
        'icon': Icons.public,
        'color': Colors.greenAccent,
      },
      {
        'name': 'fail2ban.service',
        'type': 'systemd unit',
        'status': 'active (running)',
        'description':
            'Intrusion prevention: sshd (4 retries), nginx-limit-req (2h ban)',
        'ports': 'iptables hooks',
        'icon': Icons.gavel,
        'color': Colors.greenAccent,
      },
      {
        'name': 'ufw.service',
        'type': 'systemd unit',
        'status': 'active (running)',
        'description':
            'Default DENY incoming; allows 22 (rate-limited), 80, 443 only',
        'ports': 'Netfilter / UFW',
        'icon': Icons.security,
        'color': Colors.greenAccent,
      },
      {
        'name': 'docker.service',
        'type': 'systemd unit',
        'status': 'active (running)',
        'description':
            'Docker engine daemon hosting isolated container bridge networks',
        'ports': 'unix:///var/run/docker.sock',
        'icon': Icons.inventory_2,
        'color': Colors.blueAccent,
      },
      {
        'name': 'certbot.timer',
        'type': 'systemd timer',
        'status': 'active (waiting)',
        'description':
            'Twice-daily Let\'s Encrypt certificate auto-renewal cron',
        'ports': 'ACME HTTP-01',
        'icon': Icons.lock_clock,
        'color': Colors.tealAccent,
      },
      {
        'name': 'systemd-journald',
        'type': 'systemd unit',
        'status': 'active (running)',
        'description': 'Centralized journal storage with 200MB max disk quota',
        'ports': 'kernel ring buffer',
        'icon': Icons.receipt_long,
        'color': Colors.white70,
      },
    ];

    final containers = [
      {
        'name': 'friendly-social-backend',
        'image': 'friendly-social-backend:latest',
        'network': 'friendly-social-network (bridge)',
        'internal_ip': '172.28.0.2',
        'ports': '127.0.0.1:8070->8070 (Spring Boot 3 API)',
        'health': 'Healthy (HTTP 200 /actuator/health)',
        'security':
            'Localhost-only reverse proxy binding; zero external direct port exposure.',
      },
      {
        'name': 'friendly-social-postgres',
        'image': 'postgres:16-alpine',
        'network': 'friendly-social-network (bridge)',
        'internal_ip': '172.28.0.3',
        'ports': '5432/tcp (Internal Docker bridge only; port 5433 local dev)',
        'health': 'Healthy (pg_isready)',
        'security':
            'Zero-Trust container boundary. Database access restricted to backend container.',
      },
      {
        'name': 'bybl-api',
        'image': 'bybl-api:latest',
        'network': 'app-network (bridge)',
        'internal_ip': '172.20.0.2',
        'ports': '127.0.0.1:8080 (API), 127.0.0.1:8081 (Admin)',
        'health': 'Healthy (HTTP 200)',
        'security':
            'Localhost-only proxy bindings; zero direct external access.',
      },
      {
        'name': 'bybl-db',
        'image': 'postgres:15-alpine',
        'network': 'app-network (bridge)',
        'internal_ip': '172.20.0.3',
        'ports': 'ZERO host ports exposed (5432 internal bridge only)',
        'health': 'Healthy (pg_isready)',
        'security':
            'Strict Zero-Trust isolation. Direct database connections from host or internet are impossible.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Core System Daemons (systemd)',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...services.map((svc) => _buildServiceRow(svc)),
        const SizedBox(height: 24),
        Text(
          'Containerized Production Stack (Docker Engine)',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...containers.map((c) => _buildContainerCard(c)),
      ],
    );
  }

  Widget _buildServiceRow(Map<String, dynamic> svc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(svc['icon'] as IconData, color: svc['color'] as Color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      svc['name'] as String,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        svc['status'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.greenAccent,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  svc['description'] as String,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            svc['ports'] as String,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    color: Color(0xFF00B0FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c['name'] as String,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '(${c['image']})',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c['health'] as String,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.greenAccent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network Binding: ',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: Text(
                  c['ports'] as String,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.amberAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zero-Trust Architecture: ',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: Text(
                  c['security'] as String,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkAndSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Visual Network Flow Diagram
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub, color: Color(0xFF00B0FF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Layer Defense & Routing Topology',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTopologyNode(
                      'Internet Clients',
                      'Global HTTPS Traffic',
                      Icons.language,
                      Colors.blue,
                    ),
                    _buildTopologyArrow(),
                    _buildTopologyNode(
                      'Cloudflare DNS',
                      'Automated A-Records via Terraform',
                      Icons.cloud_queue,
                      Colors.orange,
                    ),
                    _buildTopologyArrow(),
                    _buildTopologyNode(
                      'GCP Cloud Firewall',
                      'Ingress Ports 80, 443, 22 only',
                      Icons.security,
                      Colors.amber,
                    ),
                    _buildTopologyArrow(),
                    _buildTopologyNode(
                      'Host UFW + Fail2ban',
                      'Rate-limiting & IP Jails',
                      Icons.lock,
                      Colors.redAccent,
                    ),
                    _buildTopologyArrow(),
                    _buildTopologyNode(
                      'Nginx Reverse Proxy',
                      'TLS 1.3 & Static/API Zones',
                      Icons.alt_route,
                      Colors.green,
                    ),
                    _buildTopologyArrow(),
                    _buildTopologyNode(
                      'Docker Bridge / Webroot',
                      'Isolated 172.20.0.0/16 Network',
                      Icons.layers,
                      Colors.purpleAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Firewall Table
        Text(
          'UFW Host Firewall Ruleset',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildFirewallRuleRow(
                '22/tcp',
                'LIMIT IN',
                'Anywhere',
                'sshd brute-force prevention',
              ),
              const Divider(color: Colors.white10),
              _buildFirewallRuleRow(
                '80/tcp',
                'ALLOW IN',
                'Anywhere',
                'HTTP Certbot challenges & 301 redirects',
              ),
              const Divider(color: Colors.white10),
              _buildFirewallRuleRow(
                '443/tcp',
                'ALLOW IN',
                'Anywhere',
                'HTTPS TLS 1.3 production traffic',
              ),
              const Divider(color: Colors.white10),
              _buildFirewallRuleRow(
                '5432/tcp',
                'DENY IN',
                'Anywhere',
                'PostgreSQL database host lockdown',
              ),
              const Divider(color: Colors.white10),
              _buildFirewallRuleRow(
                '8080-8081',
                'DENY IN',
                'Anywhere',
                'Backend API direct port shielding',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopologyNode(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222832),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.arrow_forward, color: Colors.white30, size: 16),
    );
  }

  Widget _buildFirewallRuleRow(
    String port,
    String action,
    String from,
    String reason,
  ) {
    final isAllow = action.contains('ALLOW');
    final isLimit = action.contains('LIMIT');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text(
                        port,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isAllow
                            ? Colors.greenAccent.withValues(alpha: 0.15)
                            : isLimit
                            ? Colors.amberAccent.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        action,
                        style: GoogleFonts.jetBrainsMono(
                          color: isAllow
                              ? Colors.greenAccent
                              : isLimit
                              ? Colors.amberAccent
                              : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      from,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  port,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAllow
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : isLimit
                      ? Colors.amberAccent.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  action,
                  style: GoogleFonts.jetBrainsMono(
                    color: isAllow
                        ? Colors.greenAccent
                        : isLimit
                        ? Colors.amberAccent
                        : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 80,
                child: Text(
                  from,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  reason,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEndpointsTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 580),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                children: [
                  _buildTableHeaderCell('DOMAIN'),
                  _buildTableHeaderCell('TYPE'),
                  _buildTableHeaderCell('RATE LIMIT'),
                  _buildTableHeaderCell('STATUS'),
                  _buildTableHeaderCell('LATENCY'),
                ],
              ),
              ..._endpoints.map((ep) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        ep['domain'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        ep['type'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        ep['rateLimit'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.amberAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ep['status']}',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        '${ep['latency']} ms',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF00B0FF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
