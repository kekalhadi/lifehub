import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility untuk mendapatkan warna glass sesuai theme.
class GlassColors {
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassDark
          : AppColors.glassLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.glassBorderDark
          : AppColors.glassBorderLight;
}

/// Container dengan efek glassmorphism: semi-transparan + border halus + blur.
/// Gunakan [blur] untuk mengaktifkan BackdropFilter (default true).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool blur;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.blur = true,
    this.color,
    this.border,
    this.onTap,
    this.blurSigma = 2,
  });

  @override
  Widget build(BuildContext context) {
    final glassColor = color ?? GlassColors.bg(context);
    final glassBorder = border ??
        Border.all(color: GlassColors.border(context), width: 1);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(radius),
        border: glassBorder,
      ),
      child: child,
    );

    if (blur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Kotak ikon: background rounded hitam, ikon abu-abu.
/// Sesuai spesifikasi: "icon warna abu2 dengan background kotak rounded warna hitam".
class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final double radius;

  const IconBox({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.iconColor,
    this.backgroundColor,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.iconBoxBg : AppColors.iconBoxBg),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? AppColors.iconColor,
      ),
    );
  }
}

/// Button dengan efek inner glow (gradient + subtle highlight).
/// [variant] putih (default, untuk dark theme) atau hitam (variasi).
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final GlowButtonVariant variant;
  final bool fullWidth;
  final double radius;

  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlowButtonVariant.light,
    this.fullWidth = true,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = variant == GlowButtonVariant.light;

    // Gradient untuk efek inner glow
    final gradient = isLight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFCCCCCC)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
          );

    final textColor = isLight ? AppColors.black : AppColors.white;
    final borderColor = isLight
        ? const Color(0x33FFFFFF) // glow border untuk white
        : const Color(0x44FFFFFF); // glow border untuk dark

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            // Outer subtle glow
            BoxShadow(
              color: isLight
                  ? const Color(0x22FFFFFF)
                  : const Color(0x33000000),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GlowButtonVariant { light, dark }

/// Container dengan efek glassmorphism premium: blur tinggi, inner glow gradient,
/// highlight edge atas, dan outer glow — mirip _FinanceSummaryCard di dashboard.
class GlassCardPro extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final double blurSigma;

  const GlassCardPro({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.onTap,
    this.blurSigma = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0, left: 0, right: 0, height: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Empty state konsisten: ikon besar + teks (tanpa emoji).
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBox(
              icon: icon,
              size: 72,
              iconSize: 36,
              radius: 20,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              GlowButton(
                label: actionLabel!,
                icon: Icons.add,
                onPressed: onAction!,
                variant: GlowButtonVariant.light,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
