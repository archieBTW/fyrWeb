import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_data.dart';
import '../fyr_theme.dart';

class PortfolioAppIcon extends StatelessWidget {
  final AppInfo? app;
  final String? appId;
  final dynamic icon;
  final double size;

  const PortfolioAppIcon({
    super.key,
    this.app,
    this.appId,
    this.icon,
    this.size = 36,
  });

  String get effectiveId => (app?.id ?? appId ?? '').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final id = effectiveId;

    // 1. Built-in fyr desktop apps with assets
    final assetPath = _getAssetPath(id);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    // 2. Custom branded portfolio apps
    switch (id) {
      case 'beats_by_arch':
        return _buildBeatsLogo(size);
      case 'bybl':
        return _buildByblLogo(size);
      case 'friendly':
        return _buildFriendlyLogo(size);
      case 'welledumacated':
        return _buildWelledumacatedLogo(size);
      case 'carlyle':
        return _buildCarlyleLogo(size);
      case 'we_iac':
        return _buildWeIacLogo(size);
      case 'infra_monitor':
        return _buildInfraMonitorLogo(size);
      case 'grand_theft_ant':
        return _buildGrandTheftAntLogo(size);
      case 'resume':
        return _buildResumeLogo(size);
      case 'contact':
        return _buildContactLogo(size);
      case 'github':
        return _buildGithubLogo(size);
    }

    return _buildFallback();
  }

  String? _getAssetPath(String id) {
    switch (id) {
      case 'files':
      case 'fyrfiles':
        return 'assets/icons/folderfile.png';
      case 'settings':
      case 'fyrsettings':
        return 'assets/icons/settings.png';
      case 'terminal':
      case 'fyrterm':
        return 'assets/icons/terminal.png';
      case 'code':
      case 'fyrcode':
        return 'assets/icons/code.png';
      case 'photos':
      case 'fyrphotos':
        return 'assets/icons/photos.png';
      case 'music':
      case 'fyrmusic':
        return 'assets/icons/music.png';
      case 'browser':
      case 'fyrbrowser':
        return 'assets/icons/browser.png';
      case 'calculator':
      case 'fyrcalculator':
        return 'assets/icons/calculator.png';
      case 'clock':
      case 'fyrclock':
        return 'assets/icons/clock.png';
      case 'journal':
      case 'fyrjournal':
        return 'assets/icons/journal.png';
      case 'shop':
      case 'fyrstore':
        return 'assets/icons/shop.png';
      default:
        return null;
    }
  }

  Widget _buildBeatsLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, 0),
          radius: 0.9,
          colors: [Color(0xFF9D4EDD), Color(0xFF3C096C), Color(0xFF10002B)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFC77DFF).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          color: const Color(0xFFE0AAFF),
          size: s * 0.58,
        ),
      ),
    );
  }

  Widget _buildByblLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5364).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: const Color(0xFFFFD700),
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildFriendlyLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0844).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildWelledumacatedLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998E).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildCarlyleLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF416C).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.speed_rounded,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildWeIacLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4364F7).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.hub_rounded,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildInfraMonitorLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.monitor_heart_rounded,
          color: const Color(0xFF00E5FF),
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildGrandTheftAntLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFF7FA650).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7FA650).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.pest_control_rounded,
          color: const Color(0xFF7FA650),
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildResumeLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B4371), Color(0xFFF3904F)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3904F).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.workspace_premium_rounded,
          color: const Color(0xFFFFD700),
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildContactLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Center(
        child: Icon(
          Icons.mail_outline_rounded,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildGithubLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFF24292E),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.github,
          color: Colors.white,
          size: s * 0.55,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final effectiveIcon = icon ?? app?.icon;
    if (effectiveIcon is IconData) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (app?.color ?? FyrTheme.accentColor).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(size * 0.26),
          border: Border.all(color: (app?.color ?? FyrTheme.accentColor).withValues(alpha: 0.4)),
        ),
        child: Icon(
          effectiveIcon,
          color: app?.color ?? FyrTheme.textColor,
          size: size * 0.55,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FyrTheme.accentColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(Icons.apps, size: size * 0.55, color: FyrTheme.textColor),
    );
  }
}

