import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Maps avatar IDs to image asset paths
class AvatarAssets {
  static const String defaultMale = 'assets/images/avatars/default_male.png';
  static const String defaultFemale = 'assets/images/avatars/default_female.png';

  static const Map<String, String> imageAvatars = {
    // Defaults
    'default_male': 'assets/images/avatars/default_male.png',
    'default_female': 'assets/images/avatars/default_female.png',
    // People
    'kohen_gadol': 'assets/images/avatars/kohen_gadol.png',
    'rebbetzin': 'assets/images/avatars/rebbetzin.png',
    'talmid_chacham': 'assets/images/avatars/talmid_chacham.png',
    'chacham_sefardi': 'assets/images/avatars/chacham_sefardi.png',
    'morenu_verabenu': 'assets/images/avatars/morenu_verabenu.png',
    'tzaddik_nistar': 'assets/images/avatars/tzaddik_nistar.png',
    'tzaddeket': 'assets/images/avatars/tzaddeket.png',
    'gavra_raba': 'assets/images/avatars/gavra_raba.png',
    'navi': 'assets/images/avatars/navi.png',
    'amora': 'assets/images/avatars/amora.png',
    'lamdan': 'assets/images/avatars/lamdan.png',
    'neviah': 'assets/images/avatars/neviah.png',
    'eshet_chayil': 'assets/images/avatars/eshet_chayil.png',
    'shakdanit': 'assets/images/avatars/shakdanit.png',
    // Foods
    'jachnun': 'assets/images/avatars/jachnun.png',
    'gefilte_fish': 'assets/images/avatars/gefilte_fish.png',
    'sufganiya': 'assets/images/avatars/sufganiya.png',
    'cholent': 'assets/images/avatars/cholent.png',
    'falafel': 'assets/images/avatars/falafel.png',
    'kubeh': 'assets/images/avatars/kubeh.png',
    'bourekas': 'assets/images/avatars/bourekas.png',
    'kiddush_cup': 'assets/images/avatars/kiddush_cup.png',
    'hamantaschen': 'assets/images/avatars/hamantaschen.png',
    // Jewish items
    'chanukia': 'assets/images/avatars/chanukia.png',
    'sefer_torah': 'assets/images/avatars/sefer_torah.png',
    'beit_hamikdash': 'assets/images/avatars/beit_hamikdash.png',
  };

  /// Check if an avatar ID is an image-based avatar
  static bool isImageAvatar(String avatarId) {
    return imageAvatars.containsKey(avatarId);
  }

  /// Get the asset path for an avatar, or null if it's an emoji
  static String? getImagePath(String avatarId) {
    return imageAvatars[avatarId];
  }
}

class RabbiAvatar extends StatefulWidget {
  final String phrase;
  final int streakDays;
  final bool isFemale;
  final String avatarEmoji;
  final bool showCelebration;

  const RabbiAvatar({
    super.key,
    required this.phrase,
    required this.streakDays,
    this.isFemale = false,
    this.avatarEmoji = '',
    this.showCelebration = false,
  });

  @override
  State<RabbiAvatar> createState() => RabbiAvatarState();
}

class RabbiAvatarState extends State<RabbiAvatar>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Bobbing animation
    _bobController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _bobAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    // Glow pulse animation (active when streak > 0)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.streakDays > 0) {
      _glowController.repeat(reverse: true);
    }

    // Sparkle/celebration animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );

    if (widget.showCelebration) {
      celebrate();
    }
  }

  @override
  void didUpdateWidget(RabbiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays > 0 && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (widget.streakDays == 0 && _glowController.isAnimating) {
      _glowController.stop();
    }
    if (widget.showCelebration && !oldWidget.showCelebration) {
      celebrate();
    }
  }

  /// Trigger celebration sparkle effect
  void celebrate() {
    _sparkleController.reset();
    _sparkleController.forward();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Widget _buildAvatarCircle(List<Color> gradientColors, Color shadowColor) {
    // Determine if we should show an image or emoji
    final avatarId = widget.avatarEmoji;
    final imagePath = AvatarAssets.getImagePath(avatarId);
    final defaultImage = widget.isFemale
        ? AvatarAssets.defaultFemale
        : AvatarAssets.defaultMale;

    // Use image avatar if: specific image avatar selected, or no avatar selected (use default)
    final useImage = imagePath != null || avatarId.isEmpty;
    final assetPath = imagePath ?? defaultImage;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: useImage ? null : LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: useImage
            ? Image.asset(
                assetPath,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Center(
                  child: Text(
                    widget.isFemale ? '👩' : '🧔',
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              )
            : Center(
                child: Text(
                  avatarId,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.isFemale
        ? [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)]
        : [AppColors.deepBlue, AppColors.warmBlue];

    final shadowColor = widget.isFemale
        ? const Color(0xFF6A1B9A)
        : AppColors.deepBlue;

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sparkle particles layer
              AnimatedBuilder(
                animation: _sparkleAnimation,
                builder: (context, _) {
                  if (_sparkleAnimation.value == 0 ||
                      _sparkleAnimation.value == 1 &&
                          !_sparkleController.isAnimating) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    size: const Size(160, 160),
                    painter: _SparklePainter(
                      progress: _sparkleAnimation.value,
                    ),
                  );
                },
              ),

              // Glow ring (when streak active)
              if (widget.streakDays > 0)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold
                                .withValues(alpha: _glowAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Main avatar circle with bobbing
              AnimatedBuilder(
                animation: _bobAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bobAnimation.value),
                    child: child,
                  );
                },
                child: _buildAvatarCircle(gradientColors, shadowColor),
              ),

              // Streak badge overlay
              if (widget.streakDays > 0)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: AnimatedBuilder(
                    animation: _bobAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bobAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.streak,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.streak.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '🔥${widget.streakDays}',
                        style: GoogleFonts.rubik(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Speech bubble
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.phrase,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkBrown,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for golden sparkle particles radiating outward
class _SparklePainter extends CustomPainter {
  final double progress;
  static final Random _random = Random(42); // Fixed seed for consistent pattern
  static final List<_Particle> _particles = _generateParticles(16);

  _SparklePainter({required this.progress});

  static List<_Particle> _generateParticles(int count) {
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * pi + _random.nextDouble() * 0.5;
      return _Particle(
        angle: angle,
        speed: 0.7 + _random.nextDouble() * 0.6,
        size: 2 + _random.nextDouble() * 3,
        delay: _random.nextDouble() * 0.3,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in _particles) {
      final adjustedProgress = ((progress - particle.delay) / (1 - particle.delay))
          .clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final distance = adjustedProgress * 70 * particle.speed;
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);

      final dx = center.dx + cos(particle.angle) * distance;
      final dy = center.dy + sin(particle.angle) * distance;

      final paint = Paint()
        ..color = AppColors.gold.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      // Draw star-like sparkle
      canvas.drawCircle(Offset(dx, dy), particle.size * (1 - adjustedProgress * 0.5), paint);

      // Small cross highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final s = particle.size * 0.8;
      canvas.drawLine(
        Offset(dx - s, dy),
        Offset(dx + s, dy),
        highlightPaint,
      );
      canvas.drawLine(
        Offset(dx, dy - s),
        Offset(dx, dy + s),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
