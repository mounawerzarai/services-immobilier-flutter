import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Composants visuels partagés (mêmes rôles que src/components/ui.tsx en RN).

enum PillTone { primary, accent, danger, neutral, dark }

/// Petite pastille colorée (Vente, Location, Vendu…).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.primary, this.icon});

  final String label;
  final PillTone tone;
  final IconData? icon;

  (Color, Color) get _colors {
    switch (tone) {
      case PillTone.primary:
        return (AppColors.primarySoft, AppColors.primary);
      case PillTone.accent:
        return (AppColors.accentSoft, AppColors.accentText);
      case PillTone.danger:
        return (AppColors.dangerSoft, AppColors.danger);
      case PillTone.neutral:
        return (const Color(0xFFEEF1F3), AppColors.muted);
      case PillTone.dark:
        return (const Color(0xB814212B), Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Icône + texte gris sur une ligne (ville, surface, pièces…).
class IconText extends StatelessWidget {
  const IconText(
    this.icon,
    this.text, {
    super.key,
    this.color = AppColors.muted,
    this.size = 13,
  });

  final IconData icon;
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 2, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: size, color: color),
          ),
        ),
      ],
    );
  }
}

/// Carte blanche arrondie avec ombre douce.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: shape,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Pastille ronde colorée contenant une icône.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.size = 38,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.square = true,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color background;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(square ? size * 0.32 : size / 2),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Bouton rond blanc avec ombre (retour, filtres…), avec pastille de compteur.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.color = AppColors.text,
    this.background = AppColors.surface,
    this.badge = 0,
    this.radius,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color color;
  final Color background;
  final int badge;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? size / 2);
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: r,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, color: color, size: size * 0.48),
        ),
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badge > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19),
                height: 19,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// État vide ou d'erreur : grande icône, titre, texte, bouton.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon,
              size: 76,
              square: false,
              color: danger ? AppColors.danger : AppColors.primary,
              background: danger ? AppColors.dangerSoft : AppColors.primarySoft,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            if (text != null) ...[
              const SizedBox(height: 6),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Logo de l'application : maison dans un carré arrondi, avec le nom (option).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.light = false, this.withName = false});

  final double size;
  final bool light;
  final bool withName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: AppShadows.card,
      ),
      child: Icon(
        Icons.home_rounded,
        size: size * 0.56,
        color: light ? AppColors.primary : Colors.white,
      ),
    );
    if (!withName) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: 'Services ',
            style: TextStyle(color: light ? Colors.white : AppColors.text),
            children: [
              TextSpan(
                text: 'Immobilier',
                style: TextStyle(color: light ? AppColors.accent : AppColors.primary),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Titre de section avec action facultative à droite.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
