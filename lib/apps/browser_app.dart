import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../fyr_theme.dart';
import 'browser_view_stub.dart' if (dart.library.html) 'browser_view_web.dart';

enum BrowserViewMode { home, searchResults, externalSite }

class BrowserApp extends StatefulWidget {
  final String url;
  const BrowserApp({super.key, this.url = 'https://fyrsearch.internal'});

  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  late TextEditingController _addressController;
  late TextEditingController _searchFieldController;
  BrowserViewMode _currentMode = BrowserViewMode.home;
  String _activeSearchQuery = '';
  String _currentSiteUrl = '';
  String _activeViewId = '';
  final List<String> _history = [];
  int _historyIndex = -1;

  final List<Map<String, dynamic>> _portfolioProjects = [
    {
      'title': 'archBTW. — Terminal-Themed Music & Media Platform',
      'url': 'https://archBTW.sh',
      'displayUrl': 'archBTW.sh',
      'icon': Icons.album,
      'badge': 'Flutter Web • Nginx • Certbot • UFW • Terraform',
      'description':
          'Immersive terminal-emulator web experience housing streaming audio, merchandise catalog, real-time ASCII animations, and automated TLS 1.3 encryption with Certbot on GCP.',
      'highlights': ['Terminal Emulator', 'ASCII Art', 'Certbot TLS 1.3', 'Nginx'],
    },
    {
      'title': 'LibreTrac — Mood, Sleep, and Cognition Telemetry Dashboard',
      'url': 'https://libretrac.site',
      'displayUrl': 'libretrac.site',
      'icon': Icons.favorite,
      'badge': 'Flutter Web • AI Analytics • Multi-Line Charts',
      'description':
          'Comprehensive habit and mental wellness telemetry dashboard featuring multi-line interactive charting, LLM pattern detection for weekly user trends, and cognitive performance tracking.',
      'highlights': ['Time-Series Charts', 'AI Analytics', 'Habit Tracking'],
    },
    {
      'title': 'Beats by Arch — Lo-Fi & Instrumental Music Streaming Platform',
      'url': 'https://beats.archerwoods.dev',
      'displayUrl': 'beats.archerwoods.dev',
      'icon': Icons.music_note,
      'badge': 'Flutter Web • Audio Engine • Nginx • GCP',
      'description':
          'High-fidelity audio streaming application with real-time waveform visualization, playlist curation, and low-latency audio delivery on Arch Linux & Web. Automated zero-downtime Nginx reloads and Cloudflare DNS automation.',
      'highlights': ['Audio Engine', 'Zero-Downtime', 'GCP', 'Flutter'],
    },
    {
      'title': 'bybl — AI-Powered Bible Study Platform & Research Assistant',
      'url': 'https://bybl.dev',
      'displayUrl': 'bybl.dev',
      'icon': Icons.menu_book,
      'badge': 'Flutter • Go REST • PostgreSQL • Gemini AI',
      'description':
          'AI-augmented research application using Gemini API with dynamic prompt injection, theological lens customization, custom verse journaling, and distraction-free cross-platform reading. Zero-trust container networking.',
      'highlights': ['Gemini AI', 'Go REST API', 'Docker', 'Journaling'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: 'https://fyrsearch.internal');
    _searchFieldController = TextEditingController();

    if (widget.url.isNotEmpty &&
        widget.url != 'https://fyrsearch.internal' &&
        widget.url != 'https://duckduckgo.com') {
      _navigateToUrl(widget.url);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchFieldController.dispose();
    super.dispose();
  }

  void _navigateToUrl(String targetUrl) {
    setState(() {
      _currentSiteUrl = targetUrl;
      _addressController.text = targetUrl;
      _currentMode = BrowserViewMode.externalSite;
      _activeViewId = 'iframe-${targetUrl.hashCode}';
      registerIframe(_activeViewId, targetUrl);

      _history.add(targetUrl);
      _historyIndex = _history.length - 1;
    });
  }

  void _executeSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Check if input looks like a direct URL
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        (trimmed.contains('.') && !trimmed.contains(' '))) {
      final validUrl = trimmed.startsWith('http') ? trimmed : 'https://$trimmed';
      _navigateToUrl(validUrl);
      return;
    }

    setState(() {
      _activeSearchQuery = trimmed;
      _addressController.text = 'https://fyrsearch.internal/search?q=${Uri.encodeComponent(trimmed)}';
      _searchFieldController.text = trimmed;
      _currentMode = BrowserViewMode.searchResults;

      _history.add(_addressController.text);
      _historyIndex = _history.length - 1;
    });
  }

  void _goHome() {
    setState(() {
      _currentMode = BrowserViewMode.home;
      _addressController.text = 'https://fyrsearch.internal';
      _searchFieldController.clear();
      _activeSearchQuery = '';

      _history.add(_addressController.text);
      _historyIndex = _history.length - 1;
    });
  }

  void _goBack() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        final previous = _history[_historyIndex];
        if (previous == 'https://fyrsearch.internal') {
          _currentMode = BrowserViewMode.home;
          _addressController.text = previous;
        } else if (previous.contains('/search?q=')) {
          _currentMode = BrowserViewMode.searchResults;
          _addressController.text = previous;
          final q = Uri.parse(previous).queryParameters['q'] ?? '';
          _activeSearchQuery = q;
          _searchFieldController.text = q;
        } else {
          _currentMode = BrowserViewMode.externalSite;
          _currentSiteUrl = previous;
          _addressController.text = previous;
        }
      });
    } else {
      _goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF141416),
      child: Column(
        children: [
          // Browser Top Navigation Bar (Chrome)
          _buildBrowserToolbar(),

          // Main Viewport
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserToolbar() {
    final accentColor = FyrTheme.accentColor;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Navigation controls: Back, Forward, Refresh, Home
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(Icons.arrow_back_rounded, size: 18, color: _historyIndex > 0 ? Colors.white : Colors.white38),
            tooltip: 'Back',
            onPressed: _historyIndex > 0 ? _goBack : null,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white38),
            tooltip: 'Forward',
            onPressed: null,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
            tooltip: 'Reload',
            onPressed: () {
              if (_currentMode == BrowserViewMode.externalSite) {
                _navigateToUrl(_currentSiteUrl);
              }
            },
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(Icons.home_rounded, size: 18, color: _currentMode == BrowserViewMode.home ? accentColor : Colors.white70),
            tooltip: 'fyrSearch Home',
            onPressed: _goHome,
          ),
          const SizedBox(width: 6),

          // Address Omnibox
          Expanded(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF121214),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 13, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: _executeSearch,
                    ),
                  ),
                  if (_addressController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _addressController.clear();
                      },
                      child: const Icon(Icons.close, size: 13, color: Colors.white38),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Quick Action to open external tab
          if (_currentMode == BrowserViewMode.externalSite)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white70),
              tooltip: 'Open in new tab',
              onPressed: () {
                launchUrl(Uri.parse(_currentSiteUrl), mode: LaunchMode.externalApplication);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentMode) {
      case BrowserViewMode.home:
        return _buildSearchEngineHome();
      case BrowserViewMode.searchResults:
        return _buildSearchResultsPage();
      case BrowserViewMode.externalSite:
        return _buildExternalSiteView();
    }
  }

  // ==========================================
  // Mock Search Engine: Homepage
  // ==========================================
  Widget _buildSearchEngineHome() {
    final accentColor = FyrTheme.accentColor;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121214),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fyr Logo & Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/fyr_icon.png',
                      width: 52,
                      height: 52,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'fyrSearch',
                      style: GoogleFonts.outfit(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'ENGINEERED SEARCH & DISCOVERY ENGINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Main Search Input Capsule
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: accentColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchFieldController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search the web or portfolio projects...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _executeSearch,
                        ),
                      ),
                      if (_searchFieldController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                          onPressed: () {
                            setState(() => _searchFieldController.clear());
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _executeSearch(_searchFieldController.text.isNotEmpty ? _searchFieldController.text : 'Archer Woods Portfolio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'fyrSearch',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: () {
                        // Launch random portfolio project
                        final randomProject = (_portfolioProjects..shuffle()).first;
                        _executeSearch(randomProject['title'] as String);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "I'm Feeling Fyr",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Shortcut Tiles
                Text(
                  'FEATURED PROJECTS & SITES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _portfolioProjects.map((p) {
                    return InkWell(
                      onTap: () => _navigateToUrl(p['url']),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(p['icon'] as IconData, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            Text(
                              p['displayUrl'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Mock Search Engine: Results Page
  // ==========================================
  Widget _buildSearchResultsPage() {
    final accentColor = FyrTheme.accentColor;

    return Container(
      color: const Color(0xFF121214),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results ScrollView
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              children: [
                // Query stats
                Text(
                  'About ${_portfolioProjects.length} results (0.04 seconds) for "$_activeSearchQuery"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 12),

                // Sponsored / Top Result Callout Box
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: accentColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Showing verified engineering portfolio projects for Archer Woods matching "$_activeSearchQuery"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Results List
                ..._portfolioProjects.map((p) => _buildResultCard(p, accentColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, Color accentColor) {
    final title = item['title'] as String;
    final url = item['url'] as String;
    final displayUrl = item['displayUrl'] as String;
    final description = item['description'] as String;
    final badge = item['badge'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL line + Favicon
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF25252B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(item['icon'] as IconData, size: 12, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                'https://$displayUrl',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Clickable Title
          InkWell(
            onTap: () => _navigateToUrl(url),
            hoverColor: Colors.transparent,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8AB4F8), // Classic Google dark-mode link blue
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Architecture Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Description Snippet
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: () => _navigateToUrl(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F24),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_browser, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Text('Browse Inside App', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.launch, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text('Open External Tab', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Embedded Web View / IFrame
  // ==========================================
  Widget _buildExternalSiteView() {
    return Column(
      children: [
        // Sub-header banner showing status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: const Color(0xFF19191D),
          child: Row(
            children: [
              const Icon(Icons.public, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to: $_currentSiteUrl',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _currentMode = BrowserViewMode.searchResults),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    'Back to Search Results',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: FyrTheme.accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // IFrame Content
        Expanded(
          child: buildHtmlView(_activeViewId),
        ),
      ],
    );
  }
}
