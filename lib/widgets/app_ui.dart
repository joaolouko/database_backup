import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B1120);
  static const surface = Color(0xFF111827);
  static const surfaceAlt = Color(0xFF0F172A);
  static const border = Color(0xFF1E293B);
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF312E81);
  static const textMuted = Color(0xFF94A3B8);
  static const textSubtle = Color(0xFF64748B);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class AppPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
          ),
          child: Icon(icon, color: const Color(0xFFA5B4FC)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppSectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const AppSectionTitle({super.key, required this.title, required this.icon, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFFA5B4FC)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(color: AppColors.textSubtle, fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const AppInfoBanner({super.key, required this.message, required this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(11), border: Border.all(color: color.withValues(alpha: .30))),
      child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 10), Expanded(child: Text(message, style: TextStyle(color: color.withValues(alpha: .95), fontSize: 12)))]),
    );
  }
}
