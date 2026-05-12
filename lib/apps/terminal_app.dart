import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _history.addAll([
      'fyrWeb v1.0.0 (tty1)',
      'Welcome archie. Type "help" for a list of commands.',
      '',
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).size.width >= 600) {
        _showNeofetch();
        if (mounted) setState(() {});
      }
    });
  }

  void _showNeofetch() {
    _history.addAll([
      '            .-/+oossssoo+/-.               archie@fyrWeb',
      '        `:+ssssssssssssssssss+:`           ------------',
      '      -+ssssssssssssssssssyyssss+-         OS: fyrWeb 1.0.0 x86_64',
      '    .ossssssssssssssssssdMMMNysssso.       Host:  fyrWeb',
      '   /ssssssssssshdmmNNmmyNMMMMhssssss/      Kernel: 5.15.0-generic',
      '  +ssssssssshmydMMMMMMMNddddyssssssss+     Uptime: 2 hours, 42 mins',
      ' /sssssssshNMMMyhhyyyyhmNMMMNhssssssss/    Packages: 1337 (dpkg)',
      '.ssssssssdMMMMMMNdyysssdmMMMMMysssssssso.  Shell: zsh 5.8.1',
      'osssssssNMMMMMMMMMMMMMMMMMMMMMysssssssso   Resolution: 1920x1080',
      'osssssssNMMMMMMMMMMMMMMMMMMMMMysssssssso   DE: fyrWeb-DE',
      'osssssssNMMMMMMMMmhyyyyyyhmMMMhssssssso    WM: fyrWM',
      '.ssssssssdMMMMMMNdyysssssdmMMMysssssssso.  Theme: Glassmorphic-Dark',
      ' /sssssssshNMMMyhhyyyyhdNMMMNhssssssss/    Icons: Material-Rounded',
      '  +ssssssssshmydMMMMMMMNddddyssssssss+     Terminal: fyrTerm',
      '   /ssssssssssshdmmNNmmyNMMMMhssssss/      CPU: Virtual Core (4) @ 2.4GHz',
      '    .ossssssssssssssssssdMMMNysssso.       GPU: SwiftShader',
      '      -+ssssssssssssssssssyyssss+-         Memory: 2048MiB / 8192MiB',
      '        `:+ssssssssssssssssss+:`',
      '            .-/+oossssoo+/-.',
    ]);
  }

  void _handleCommand(String cmd) {
    setState(() {
      _history.add('archie@fyrWeb:~\$ $cmd');
      switch (cmd.toLowerCase().trim()) {
        case 'neofetch':
          _showNeofetch();
          break;
        case 'help':
          _history.add(
            'Available commands: help, clear, ls, whoami, date, uname, neofetch',
          );
          break;
        case 'clear':
          _history.clear();
          return;
        case 'ls':
          _history.add(
            '-rw-r--r--  1 archie  staff  1.2K May 12 15:47  about_me.txt',
          );
          break;
        case 'whoami':
          _history.add('archie');
          break;
        case 'date':
          _history.add(DateTime.now().toString());
          break;
        case 'uname':
          _history.add('fyrWeb 5.15.0-generic x86_64');
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
                    'archie@fyrWeb:~\$ ',
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
