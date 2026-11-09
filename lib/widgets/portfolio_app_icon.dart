import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_data.dart';
import '../fyr_theme.dart';

class PortfolioAppIcon extends StatelessWidget {
  final AppInfo? app;
  final String? appId;
  final dynamic icon;
  final double size;
  final bool solidBackground;

  const PortfolioAppIcon({
    super.key,
    this.app,
    this.appId,
    this.icon,
    this.size = 36,
    this.solidBackground = false,
  });

  String get effectiveId => (app?.id ?? appId ?? '').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final id = effectiveId;

    // 1. Built-in fyr desktop apps with assets
    final assetPath = _getAssetPath(id);
    if (assetPath != null) {
      if (solidBackground) {
        final bgColor = _getSystemAppBgColor(id, app?.color ?? const Color(0xFF2C3E50));
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(size * 0.26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              assetPath,
              width: size * 0.64,
              height: size * 0.64,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            ),
          ),
        );
      }
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
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
      case 'pycontui':
        return _buildPyConTuiLogo(size);
      case 'archbtw':
        return _buildArchBtwLogo(size);
      case 'libretrac':
        return _buildLibreTracLogo(size);
      case 'fyr':
        return _buildFyrLogo(size);
      case 'theolivebranch':
        return _buildTheOliveBranchLogo(size);
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

  Widget _buildArchBtwLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, 0),
          radius: 0.95,
          colors: [Color(0xFF9C27B0), Color(0xFF4A148C), Color(0xFF140026)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFCE93D8).withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          color: const Color(0xFFF3E5F5),
          size: s * 0.58,
        ),
      ),
    );
  }

  Widget _buildLibreTracLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF2A6D), Color(0xFFD81B60), Color(0xFF880E4F)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFFF80AB).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD81B60).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.monitor_heart_rounded,
          color: const Color(0xFFFFF0F5),
          size: s * 0.58,
        ),
      ),
    );
  }

  Widget _buildPyConTuiLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF0D3311), Color(0xFF041907)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFF69F0AE).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.terminal_rounded,
          color: const Color(0xFF69F0AE),
          size: s * 0.58,
        ),
      ),
    );
  }

  Widget _buildFyrLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9800), Color(0xFFF57C00), Color(0xFFE65100)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFFFFCC80).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/icons/fyr_icon.png',
          width: s * 0.65,
          height: s * 0.65,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: s * 0.58,
          ),
        ),
      ),
    );
  }

  Widget _buildTheOliveBranchLogo(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37474F), Color(0xFF263238), Color(0xFF102027)],
        ),
        borderRadius: BorderRadius.circular(s * 0.26),
        border: Border.all(color: const Color(0xFF90A4AE).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF37474F).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          color: const Color(0xFFECEFF1),
          size: s * 0.58,
        ),
      ),
    );
  }

  Color _getSystemAppBgColor(String id, Color defaultColor) {
    switch (id) {
      case 'browser':
      case 'fyrbrowser':
        return const Color(0xFF1976D2);
      case 'terminal':
      case 'fyrterm':
        return const Color(0xFF212529);
      case 'files':
      case 'fyrfiles':
        return const Color(0xFF0288D1);
      case 'code':
      case 'fyrcode':
        return const Color(0xFF1E293B);
      case 'photos':
      case 'fyrphotos':
        return const Color(0xFF7B1FA2);
      case 'music':
      case 'fyrmusic':
        return const Color(0xFF00796B);
      case 'settings':
      case 'fyrsettings':
        return const Color(0xFF455A64);
      case 'calculator':
      case 'fyrcalculator':
        return const Color(0xFFE65100);
      case 'clock':
      case 'fyrclock':
        return const Color(0xFF283593);
      case 'journal':
      case 'fyrjournal':
        return const Color(0xFF5D4037);
      case 'shop':
      case 'fyrstore':
        return const Color(0xFF2E7D32);
      default:
        return defaultColor;
    }
  }

  Widget _buildFallback() {
    final effectiveIcon = icon ?? app?.icon;
    final color = app?.color ?? FyrTheme.accentColor;

    final Widget glyphWidget;
    if (effectiveIcon is IconData) {
      glyphWidget = Icon(
        effectiveIcon,
        color: Colors.white,
        size: size * 0.55,
      );
    } else if (effectiveIcon is Widget) {
      glyphWidget = SizedBox(
        width: size * 0.6,
        height: size * 0.6,
        child: Center(child: effectiveIcon),
      );
    } else {
      glyphWidget = Icon(
        Icons.apps_rounded,
        size: size * 0.55,
        color: Colors.white,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: glyphWidget),
    );
  }
}

