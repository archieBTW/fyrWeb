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
      '${config.profile.systemName} v1.0.0 (tty1)',
      'Welcome ${config.profile.terminalName}. Type "help" for a list of commands.',
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
                      'Name: ${config.profile.name}\nTitle: ${config.profile.title}\nContact: arch@archerwoods.dev',
                ),
                'notes.txt': _FileNode(
                  name: 'notes.txt',
                  content: 'You found me 🫣.',
                ),
                'projects': _FileNode(
                  name: 'projects',
                  isDirectory: true,
                  children: {
                    'secret_project.txt': _FileNode(
                      name: 'secret_project.txt',
                      content: 'What is stage 2?',
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
            'config': _FileNode(name: 'config', content: 'system_mode=awesome'),
          },
        ),
      },
    );

    _root.children!['home']!.parent = _root;
    _root.children!['etc']!.parent = _root;

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
      '                  %%%                       ------------',
      '                  % %%%                     OS: ${config.profile.systemName} 1.0.0 x86_64',
      '                 %% %%%                     Host:  ${config.profile.systemName}',
      '                %%% %%%  %%                 Kernel: 5.15.0-generic',
      '              %%%  %%% %%%                  Uptime: 2 hours, 42 mins',
      '            %%%   %%%%% %                   Packages: 1337 (dpkg)',
      '           %%%   %% %%  %%                  Shell: zsh 5.8.1',
      '          %%%%          %%%                 Resolution: 1920x1080',
      '          %%%%#   % %. %%%%%                DE: ${config.profile.systemName}-DE',
      '         %%%%% %% % %%%%%%%%%               WM: fyrWM',
      '         %%%%% %% % %%%%%%%%%               Theme: Glassmorphic-Dark',
      '          %%%% %%%% %%%%%%%%%               Icons: Material-Rounded',
      '          %%%%%%%%%%%%%%%%%%                Terminal: fyrTerm',
      '            %%%        %%%                  CPU: Virtual Core (4) @ 2.4GHz',
      '               %%%%%%%                      GPU: SwiftShader',
      '                                            Memory: 2048MiB / 8192MiB',
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

      final parts = input.trim().split(' ');
      final cmd = parts[0].toLowerCase();
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      switch (cmd) {
        case 'neofetch':
          _showNeofetch();
          break;
        case 'help':
          _history.add(
            'Available commands: help, clear, whoami, date, uname, neofetch, pwd, ls, cd, cat',
          );
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
            _history.add(
              'ls: cannot access \'$targetPath\': No such file or directory',
            );
          } else if (!node.isDirectory) {
            _history.add(node.name);
          } else {
            if (node.children == null || node.children!.isEmpty) {
              // Empty dir
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
          _history.add(DateTime.now().toString());
          break;
        case 'uname':
          _history.add('${config.profile.systemName} 5.15.0-generic x86_64');
          break;
        case '':
          break;
        default:
          _history.add('Command not found: $cmd');
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
        color: isDark ? Colors.black : Colors.black87,
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._history.map(
                (line) => Text(
                  line,
                  style: GoogleFonts.firaCode(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${config.profile.terminalName}@${config.profile.systemName}:$promptPath\$ ',
                    style: GoogleFonts.firaCode(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      cursorColor: Colors.greenAccent,
                      style: GoogleFonts.firaCode(
                        color: Colors.greenAccent,
                        fontSize: 14,
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
