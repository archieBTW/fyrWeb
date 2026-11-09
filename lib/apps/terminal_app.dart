import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/config_model.dart';

class _FileNode {
  final String name;
  final String? content;
  final bool isDirectory;
  final Map<String, _FileNode>? children;
  _FileNode? parent;

  _FileNode({
    required this.name,
    this.content,
    this.isDirectory = false,
    this.children,
  }) {
    children?.values.forEach((child) => child.parent = this);
  }
}

class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  final List<String> _history = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late _FileNode _root;
  late _FileNode _currentDir;

  @override
  void initState() {
    super.initState();
    _initFileSystem();

    final config = context.read<AppConfig>();
    _history.addAll([
      '${config.profile.systemName} v1.0.0 (tty1) [Debian GNU/Linux 12 x86_64]',
      'Welcome ${config.profile.terminalName}. Type "help" to see available development, SysAdmin & DevOps commands.',
      '',
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).size.width >= 600) {
        _showNeofetch();
        if (mounted) setState(() {});
      }
    });
  }

  void _initFileSystem() {
    final config = context.read<AppConfig>();
    _root = _FileNode(
      name: '/',
      isDirectory: true,
      children: {
        'home': _FileNode(
          name: 'home',
          isDirectory: true,
          children: {
            config.profile.terminalName: _FileNode(
              name: config.profile.terminalName,
              isDirectory: true,
              children: {
                'resume.txt': _FileNode(
                  name: 'resume.txt',
                  content:
                      'Name: ${config.profile.name}\nTitle: ${config.profile.title}\nContact: ${config.profile.email}\nCertifications: LPIC-1, SUSE CLA, Linux+, Network+, A+',
                ),
                'notes.txt': _FileNode(
                  name: 'notes.txt',
                  content: 'SysAdmin roots -> Full-Stack Developer -> Cloud & DevOps Engineer.',
                ),
                'projects': _FileNode(
                  name: 'projects',
                  isDirectory: true,
                  children: {
                    'stack.txt': _FileNode(
                      name: 'stack.txt',
                      content: 'GCP e2-micro, Terraform, Ansible, Docker Compose, Nginx, UFW, Fail2ban, Flutter Web, Go.',
                    ),
                  },
                ),
              },
            ),
          },
        ),
        'etc': _FileNode(
          name: 'etc',
          isDirectory: true,
          children: {
            'sysctl.d': _FileNode(
              name: 'sysctl.d',
              isDirectory: true,
              children: {
                '99-performance.conf': _FileNode(
                  name: '99-performance.conf',
                  content: 'vm.swappiness = 20\nvm.vfs_cache_pressure = 50\nnet.ipv4.tcp_syncookies = 1\nnet.ipv4.conf.all.rp_filter = 1\nnet.ipv4.conf.all.accept_source_route = 0',
                ),
              },
            ),
            'nginx': _FileNode(
              name: 'nginx',
              isDirectory: true,
              children: {
                'nginx.conf': _FileNode(
                  name: 'nginx.conf',
                  content: 'events { worker_connections 1024; }\nhttp {\n  limit_req_zone \$binary_remote_addr zone=static_site:10m rate=30r/s;\n  limit_req_zone \$binary_remote_addr zone=api_zone:10m rate=20r/s;\n  limit_conn_zone \$binary_remote_addr zone=addr:10m;\n}',
                ),
                'sites-available': _FileNode(
                  name: 'sites-available',
                  isDirectory: true,
                  children: {
                    'bybl.dev.conf': _FileNode(
                      name: 'bybl.dev.conf',
                      content: 'server {\n  server_name bybl.dev www.bybl.dev;\n  root /var/www/bybl.dev/html;\n  limit_req zone=static_site burst=50 nodelay;\n  ssl_protocols TLSv1.2 TLSv1.3;\n}',
                    ),
                    'api.bybl.dev.conf': _FileNode(
                      name: 'api.bybl.dev.conf',
                      content: 'server {\n  server_name api.bybl.dev;\n  limit_req zone=api_zone burst=30 nodelay;\n  location / {\n    proxy_pass http://127.0.0.1:8080;\n    proxy_set_header Host \$host;\n    proxy_set_header X-Real-IP \$remote_addr;\n  }\n}',
                    ),
                  },
                ),
              },
            ),
            'fail2ban': _FileNode(
              name: 'fail2ban',
              isDirectory: true,
              children: {
                'jail.local': _FileNode(
                  name: 'jail.local',
                  content: '[sshd]\nenabled = true\nmaxretry = 4\nbantime = 2h\n\n[nginx-limit-req]\nenabled = true\nport = http,https\nlogpath = /var/log/nginx/error.log\nfindtime = 2m\nmaxretry = 10\nbantime = 1h\n\n[nginx-botsearch]\nenabled = true\nport = http,https\nlogpath = /var/log/nginx/error.log\nmaxretry = 3\nbantime = 24h',
                ),
              },
            ),
          },
        ),
        'opt': _FileNode(
          name: 'opt',
          isDirectory: true,
          children: {
            'WE-IAC': _FileNode(
              name: 'WE-IAC',
              isDirectory: true,
              children: {
                'architecture.txt': _FileNode(
                  name: 'architecture.txt',
                  content: 'Cloudflare DNS -> GCP Firewall -> Host UFW + Fail2ban -> Nginx (Rate Limited) -> Docker Bridge (172.20.0.0/16)',
                ),
              },
            ),
            'bybl': _FileNode(
              name: 'bybl',
              isDirectory: true,
              children: {
                'docker-compose.yml': _FileNode(
                  name: 'docker-compose.yml',
                  content: 'version: "3.8"\nservices:\n  bybl-db:\n    image: postgres:16-alpine\n    networks:\n      - app-network\n    # ZERO HOST PORTS MAPPED (Strict Zero-Trust)\n  bybl-api:\n    image: bybl-api:latest\n    ports:\n      - "127.0.0.1:8080:8080"\n      - "127.0.0.1:8081:8081"\n    networks:\n      - app-network',
                ),
              },
            ),
          },
        ),
      },
    );

    _root.children!['home']!.parent = _root;
    _root.children!['etc']!.parent = _root;
    _root.children!['opt']!.parent = _root;

    _currentDir =
        _root.children!['home']!.children![config.profile.terminalName]!;
  }

  _FileNode? _getNode(String path) {
    if (path.isEmpty) return _currentDir;

    _FileNode current = path.startsWith('/') ? _root : _currentDir;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    for (final part in parts) {
      if (part == '.') continue;
      if (part == '~') {
        final config = context.read<AppConfig>();
        current =
            _root.children!['home']!.children![config.profile.terminalName]!;
        continue;
      }
      if (part == '..') {
        current = current.parent ?? current;
      } else {
        if (!current.isDirectory ||
            current.children == null ||
            !current.children!.containsKey(part)) {
          return null;
        }
        current = current.children![part]!;
      }
    }
    return current;
  }

  String _getAbsolutePath(_FileNode node) {
    if (node == _root) return '/';
    final List<String> parts = [];
    _FileNode? current = node;
    while (current != null && current != _root) {
      parts.insert(0, current.name);
      current = current.parent;
    }
    return '/${parts.join('/')}';
  }

  void _showNeofetch() {
    final config = context.read<AppConfig>();
    _history.addAll([
      '                  %                         ${config.profile.terminalName}@${config.profile.systemName}',
      '                  %%%                       ----------------------------------------',
      '                  % %%%                     OS: Debian GNU/Linux 12 (Bookworm) x86_64',
      '                 %% %%%                     Host: Google Cloud Compute Engine (e2-micro)',
      '                %%% %%%  %%                 Kernel: 5.15.0-generic (LPIC-1 Hardened)',
      '              %%%  %%% %%%                  Uptime: 52 days, 18 hours, 32 mins',
      '            %%%   %%%%% %                   Packages: 1420 (dpkg), 2 (docker containers)',
      '           %%%   %% %%  %%                  Shell: zsh 5.9',
      '          %%%%          %%%                 DE: ${config.profile.systemName}-DE (Flutter Web Shell)',
      '          %%%%#   % %. %%%%%                WM: fyrWM',
      '         %%%%% %% % %%%%%%%%%               Firewall: UFW (Default DENY) + Fail2ban',
      '         %%%%% %% % %%%%%%%%%               Reverse Proxy: Nginx 1.22 (TLS 1.3, Rate-Limited)',
      '          %%%% %%%% %%%%%%%%%               IaC Engine: Terraform + Ansible (WE-IAC)',
      '          %%%%%%%%%%%%%%%%%%                CPU: Virtual Core (2) @ 2.20GHz',
      '            %%%        %%%                  Memory: 718MiB / 1024MiB (RAM) + 224MiB / 2048MiB (Swap)',
      '               %%%%%%%                      Disk: 8.4G / 20G (pd-balanced rootfs)',
    ]);
  }

  void _handleCommand(String input) {
    final config = context.read<AppConfig>();
    final promptPath = _getAbsolutePath(
      _currentDir,
    ).replaceFirst('/home/${config.profile.terminalName}', '~');

    setState(() {
      _history.add(
        '${config.profile.terminalName}@${config.profile.systemName}:$promptPath\$ $input',
      );

      final trimmed = input.trim();
      final parts = trimmed.split(' ').where((s) => s.isNotEmpty).toList();
      final cmd = parts.isNotEmpty ? parts[0].toLowerCase() : '';
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      switch (cmd) {
        case 'neofetch':
          _showNeofetch();
          break;
        case 'help':
          _history.addAll([
            '=== Built-in Shell & System Commands ===',
            '  help, clear, whoami, date, uname, uptime, pwd, ls, cd, cat, free, df',
            '',
            '=== SysAdmin & Linux Diagnostics ===',
            '  systemctl status <service>  (e.g. nginx, fail2ban, ufw, docker)',
            '  ufw status [verbose]        (Inspect host firewall ruleset)',
            '  htop / top                  (Display real-time process table & load)',
            '  sysctl -p                   (Inspect kernel memory & socket tuning)',
            '',
            '=== DevOps & Cloud Infrastructure ===',
            '  docker ps                   (List zero-trust containers & port bindings)',
            '  docker stats                (Inspect container memory/CPU metrics)',
            '  terraform show              (Inspect managed GCP compute & Cloudflare DNS)',
            '  ansible-playbook <playbook> (Simulate multi-site deployment orchestration)',
            '  curl <endpoint>             (Probe internal or external service health)',
          ]);
          break;
        case 'clear':
          _history.clear();
          return;
        case 'pwd':
          _history.add(_getAbsolutePath(_currentDir));
          break;
        case 'ls':
          final targetPath = args.isNotEmpty ? args[0] : '';
          final node = _getNode(targetPath);
          if (node == null) {
            _history.add('ls: cannot access \'$targetPath\': No such file or directory');
          } else if (!node.isDirectory) {
            _history.add(node.name);
          } else {
            if (node.children == null || node.children!.isEmpty) {
              // empty
            } else {
              final files = node.children!.values
                  .map((c) => c.isDirectory ? '${c.name}/' : c.name)
                  .join('  ');
              _history.add(files);
            }
          }
          break;
        case 'cd':
          final targetPath = args.isNotEmpty ? args[0] : '~';
          final node = _getNode(targetPath);
          if (node == null) {
            _history.add('cd: $targetPath: No such file or directory');
          } else if (!node.isDirectory) {
            _history.add('cd: $targetPath: Not a directory');
          } else {
            _currentDir = node;
          }
          break;
        case 'cat':
          if (args.isEmpty) {
            _history.add('cat: missing operand');
          } else {
            final node = _getNode(args[0]);
            if (node == null) {
              _history.add('cat: ${args[0]}: No such file or directory');
            } else if (node.isDirectory) {
              _history.add('cat: ${args[0]}: Is a directory');
            } else {
              _history.addAll(node.content?.split('\n') ?? []);
            }
          }
          break;
        case 'whoami':
          _history.add(config.profile.terminalName);
          break;
        case 'date':
          _history.add(DateTime.now().toUtc().toString());
          break;
        case 'uname':
          _history.add('Linux gcp-production-us-central1 5.15.0-generic #1 SMP Debian x86_64 GNU/Linux');
          break;
        case 'uptime':
          _history.add(' 18:54:10 up 52 days, 18:32,  1 user,  load average: 0.18, 0.22, 0.19');
          break;
        case 'free':
        case 'free -h':
        case 'free -m':
          _history.addAll([
            '               total        used        free      shared  buff/cache   available',
            'Mem:           992Mi       718Mi       184Mi        12Mi        90Mi       262Mi',
            'Swap:         2047Mi       224Mi      1823Mi',
          ]);
          break;
        case 'df':
        case 'df -h':
          _history.addAll([
            'Filesystem      Size  Used Avail Use% Mounted on',
            '/dev/root        20G  8.4G   11G  42% /',
            'tmpfs           496M     0  496M   0% /dev/shm',
            'tmpfs           199M  1.1M  198M   1% /run',
          ]);
          break;
        case 'sysctl':
        case 'sysctl -p':
          _history.addAll([
            'vm.swappiness = 20',
            'vm.vfs_cache_pressure = 50',
            'net.ipv4.tcp_syncookies = 1',
            'net.ipv4.conf.all.rp_filter = 1',
            'net.ipv4.conf.all.accept_source_route = 0',
          ]);
          break;
        case 'docker':
          final sub = args.isNotEmpty ? args[0] : '';
          if (sub == 'ps') {
            _history.addAll([
              'CONTAINER ID   IMAGE                          COMMAND                  CREATED        STATUS                   PORTS                                            NAMES',
              'f8b21c4e90a1   friendly-social-backend:latest "java -jar app.jar"      2 days ago     Up 2 days (healthy)      127.0.0.1:8070->8070/tcp                         friendly-social-backend',
              'c3d9014f77b2   postgres:16-alpine             "docker-entrypoint.s…"   2 days ago     Up 2 days (healthy)      5432/tcp [friendly-social-network bridge only]   friendly-social-postgres',
              'a4f891b2c3d1   bybl-api:latest                "/app/bybl-api"          4 days ago     Up 4 days (healthy)      127.0.0.1:8080->8080/tcp, 127.0.0.1:8081->8081   bybl-api',
              'e7c9103a228f   postgres:15-alpine             "docker-entrypoint.s…"   4 days ago     Up 4 days (healthy)      5432/tcp [app-network bridge only]               bybl-db',
            ]);
          } else if (sub == 'stats') {
            _history.addAll([
              'CONTAINER ID   NAME       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O         PIDS',
              'a4f891b2c3d1   bybl-api   0.45%     84.2MiB / 992MiB      8.48%     142MB / 1.1GB     12.4MB / 4.2MB    12',
              'e7c9103a228f   bybl-db    0.12%     142.1MiB / 992MiB     14.32%    1.1GB / 142MB     68.1MB / 180MB    9',
            ]);
          } else if (sub == 'images') {
            _history.addAll([
              'REPOSITORY           TAG       IMAGE ID       CREATED        SIZE',
              'bybl-api             latest    a4f891b2c3d1   4 days ago     64.2MB',
              'postgres             15-alpine e7c9103a228f   2 weeks ago    88.5MB',
            ]);
          } else {
            _history.add('Usage: docker [ps | stats | images]');
          }
          break;
        case 'systemctl':
          final sub = args.isNotEmpty ? args[0] : '';
          final unit = args.length > 1 ? args[1] : '';
          if (sub == 'status') {
            if (unit.contains('nginx')) {
              _history.addAll([
                '● nginx.service - A high performance web server and a reverse proxy server',
                '     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)',
                '     Active: active (running) since Sun 2026-10-18 04:12:08 UTC; 19 days ago',
                '   Main PID: 1824 (nginx)',
                '      Tasks: 3 (limit: 1146)',
                '     Memory: 28.4M',
                '        CPU: 18min 42.102s',
                '     CGroup: /system.slice/nginx.service',
                '             ├─1824 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;',
                '             ├─1825 nginx: worker process (static_site zone active: 30r/s)',
                '             └─1826 nginx: worker process (api_zone active: 20r/s)',
              ]);
            } else if (unit.contains('fail2ban')) {
              _history.addAll([
                '● fail2ban.service - Fail2Ban Service',
                '     Loaded: loaded (/lib/systemd/system/fail2ban.service; enabled; vendor preset: enabled)',
                '     Active: active (running) since Sun 2026-10-18 04:11:15 UTC; 19 days ago',
                '   Jails (3): sshd, nginx-limit-req, nginx-botsearch',
                '   Currently banned IPs: 0 (total banned: 42)',
              ]);
            } else if (unit.contains('ufw')) {
              _history.addAll([
                '● ufw.service - Uncomplicated firewall',
                '     Loaded: loaded (/lib/systemd/system/ufw.service; enabled; vendor preset: enabled)',
                '     Active: active (exited) since Sun 2026-10-18 04:10:40 UTC; 19 days ago',
                '     Status: Firewalled with Netfilter iptables (Default DENY)',
              ]);
            } else if (unit.contains('docker')) {
              _history.addAll([
                '● docker.service - Docker Application Container Engine',
                '     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)',
                '     Active: active (running) since Sun 2026-10-18 04:11:02 UTC; 19 days ago',
                '   Network: app-network (172.20.0.0/16)',
              ]);
            } else {
              _history.add('Unit $unit is active (running)');
            }
          } else {
            _history.add('Usage: systemctl status <nginx | fail2ban | ufw | docker>');
          }
          break;
        case 'ufw':
          _history.addAll([
            'Status: active',
            'Logging: on (low)',
            'Default: deny (incoming), allow (outgoing), disabled (routed)',
            'New profiles: skip',
            '',
            'To                         Action      From',
            '--                         ------      ----',
            '22/tcp                     LIMIT IN    Anywhere                   # sshd rate-limited',
            '80/tcp                     ALLOW IN    Anywhere                   # Certbot ACME & HTTP',
            '443/tcp                    ALLOW IN    Anywhere                   # HTTPS TLS 1.3',
            '5432                       DENY IN     Anywhere                   # Postgres host isolation',
            '8080-8081                 DENY IN     Anywhere                   # Backend local proxy only',
          ]);
          break;
        case 'terraform':
          final sub = args.isNotEmpty ? args[0] : '';
          if (sub == 'show' || sub == 'state' || sub.isEmpty) {
            _history.addAll([
              '# Managed by Terraform (WE-IAC)',
              'google_compute_address.static_ip: (34.174.x.x reserved)',
              'google_compute_instance.web_server: (e2-micro in us-central1-a, pd-balanced 20GB)',
              'cloudflare_record.bybl_a: (A -> 34.174.x.x, proxied = false)',
              'cloudflare_record.api_bybl: (A -> 34.174.x.x, proxied = false)',
              'cloudflare_record.archbtw: (A -> 34.174.x.x, proxied = false)',
              'cloudflare_record.libretrac: (A -> 34.174.x.x, proxied = false)',
              'cloudflare_record.archerwoods: (A -> 34.174.x.x, proxied = false)',
              'Outputs: instance_public_ip = "34.174.x.x", inventory_path = "../ansible/inventory.ini"',
            ]);
          } else {
            _history.add('Usage: terraform show');
          }
          break;
        case 'ansible-playbook':
          _history.addAll([
            'PLAY [Provision and Deploy Web Infrastructure] *********************************',
            '',
            'TASK [Gathering Facts] *********************************************************',
            'ok: [gcp-web]',
            '',
            'TASK [common : Configure 2GB swap space and kernel sysctl] *********************',
            'ok: [gcp-web]',
            '',
            'TASK [firewall : Configure UFW rules & Fail2ban jails] *************************',
            'ok: [gcp-web]',
            '',
            'TASK [docker : Ensure Docker engine & internal app-network exist] **************',
            'ok: [gcp-web]',
            '',
            'TASK [nginx : Deploy virtualhost configs with rate-limiting zones] *************',
            'changed: [gcp-web]',
            '',
            'TASK [static_sites : Synchronize compiled web artifacts] **********************',
            'changed: [gcp-web]',
            '',
            'PLAY RECAP *********************************************************************',
            'gcp-web                    : ok=28   changed=2    unreachable=0    failed=0    skipped=3',
          ]);
          break;
        case 'htop':
        case 'top':
          _history.addAll([
            'top - 18:54:30 up 52 days, 18:32,  1 user,  load average: 0.18, 0.22, 0.19',
            'Tasks:  78 total,   1 running,  77 sleeping,   0 stopped,   0 zombie',
            '%Cpu(s):  2.1 us,  1.4 sy,  0.0 ni, 96.2 id,  0.3 wa,  0.0 hi,  0.0 si',
            'MiB Mem :    992.0 total,    184.2 free,    718.0 used,     89.8 buff/cache',
            'MiB Swap:   2048.0 total,   1824.0 free,    224.0 used.    262.0 avail Mem',
            '',
            '  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND',
            ' 1824 www-data  20   0  142104  28412  11200 S   1.8   2.8  18:42.10 nginx',
            ' 2401 root      20   0  712400  84210  32104 S   0.9   8.5  42:15.30 bybl-api',
            ' 2390 postgres  20   0  384120 142110  28900 S   0.4  14.3  14:02.12 postgres',
            ' 1120 root      20   0   48120  14200   8120 S   0.1   1.4   4:10.15 fail2ban-server',
          ]);
          break;
        case 'curl':
          final target = args.isNotEmpty ? args[0] : '';
          _history.addAll([
            'HTTP/2 200 OK',
            'server: nginx/1.22.1',
            'date: ${DateTime.now().toUtc()}',
            'content-type: application/json; charset=utf-8',
            'strict-transport-security: max-age=31536000; includeSubDomains',
            'x-rate-limit: active (static: 30r/s, api: 20r/s)',
            '',
            '{"status":"healthy","target":"$target","service":"operational","env":"production"}',
          ]);
          break;
        case '':
          break;
        default:
          _history.add('Command not found: $cmd. Type "help" to see available commands.');
      }
      _history.add('');
    });

    _controller.clear();
    _focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = context.watch<AppConfig>();
    final promptPath = _getAbsolutePath(
      _currentDir,
    ).replaceFirst('/home/${config.profile.terminalName}', '~');

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: isDark ? const Color(0xFF000000) : Colors.black87,
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._history.map(
                (line) => Text(
                  line,
                  style: GoogleFonts.jetBrainsMono(
                    color: line.startsWith('PLAY RECAP') || line.contains('HEALTHY') || line.contains('ok=')
                        ? Colors.greenAccent
                        : line.contains('changed:') || line.contains('changed=')
                            ? Colors.amberAccent
                            : line.contains('failed=') && !line.contains('failed=0')
                                ? Colors.redAccent
                                : line.startsWith('===')
                                    ? const Color(0xFF00B0FF)
                                    : Colors.greenAccent.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${config.profile.terminalName}@${config.profile.systemName}:$promptPath\$ ',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF00B0FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      cursorColor: Colors.greenAccent,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _handleCommand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
