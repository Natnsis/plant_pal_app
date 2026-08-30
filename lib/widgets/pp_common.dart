import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';

/// Bundled avatar shown for a user who hasn't set a profile picture.
const String kProfilePlaceholderAsset = 'assets/img/profile';

/// Rounded plant photo. Shows [imageUrl] when given (with a graceful
/// placeholder while it loads or if it fails), otherwise the soft green
/// gradient + faded sprout placeholder the mockups use.
class PlantImage extends StatelessWidget {
  const PlantImage({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.radius = 20,
    this.dark = false,
    this.iconSize = 58,
    this.fit = BoxFit.cover,
    this.child,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final double radius;
  final bool dark;
  final double iconSize;
  final BoxFit fit;
  final Widget? child;

  Widget _placeholder() => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: dark ? null : PP.plantImage,
          color: dark ? PP.bone.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: child ??
            Icon(
              LucideIcons.sprout,
              size: iconSize,
              color: (dark ? PP.mint : PP.forest)
                  .withValues(alpha: dark ? 0.5 : 0.38),
            ),
      );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (context, _, _) => _placeholder(),
      ),
    );
  }
}

/// Small square icon button used across headers.
class SquircleIconButton extends StatelessWidget {
  const SquircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.radius = 15,
    this.background,
    this.foreground = PP.ink,
    this.iconSize = 18,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double radius;
  final Color? background;
  final Color foreground;
  final double iconSize;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background ?? PP.card.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(icon, size: iconSize, color: foreground),
          ),
          if (badge)
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: PP.forest,
                  shape: BoxShape.circle,
                  border: Border.all(color: PP.bone, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rounded circular back / close chevron button (used on hero screens).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.background,
    this.foreground = PP.ink,
    this.iconSize = 19,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? PP.card.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: foreground),
      ),
    );
  }
}

/// Pill tag — the little rounded label used for tags, categories, statuses.
class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    this.background = PP.pale2,
    this.foreground = PP.forest,
    this.icon,
    this.uppercase = false,
    this.fontSize = 12.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool uppercase;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: foreground),
            const SizedBox(width: 8),
          ],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: TextStyle(
              fontSize: uppercase ? 11 : fontSize,
              fontWeight: uppercase ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: uppercase ? 0.6 : 0,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width dark primary button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.background = PP.ink,
    this.foreground = PP.bone,
    this.padding = 19,
    this.fontSize = 15.5,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: padding),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(32),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional trailing link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.onTrailingTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: PP.track(19, -0.025),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PP.forest,
              ),
            ),
          ),
      ],
    );
  }
}

/// The big screen title (e.g. "Curated plants\nfor your space").
class DisplayTitle extends StatelessWidget {
  const DisplayTitle(this.text, {super.key, this.fontSize = 32});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: PP.track(fontSize),
      ),
    );
  }
}

/// A rounded task row: check circle + title/subtitle + trailing widget.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onToggle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done ? PP.doneCard : PP.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? PP.forest : Colors.transparent,
                border: Border.all(
                  color: done ? PP.forest : PP.inkA(0.22),
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 18, color: PP.bone)
                  : null,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: PP.track(15, -0.01),
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? PP.inkA(0.55) : PP.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Filter / segmented chip.
class FilterChipPP extends StatelessWidget {
  const FilterChipPP({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.showClose = false,
    this.selectedBg = PP.pale2,
    this.selectedFg = PP.forest,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showClose;
  final Color selectedBg;
  final Color selectedFg;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? selectedBg : PP.card;
    final fg = selected ? selectedFg : PP.inkA(0.6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            if (showClose && selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.close_rounded, size: 12, color: fg.withValues(alpha: 0.55)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Round avatar. Shows [imageUrl] when set, otherwise the user's [initials]
/// on the soft green gradient.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(
    this.initials, {
    super.key,
    this.imageUrl,
    this.placeholderAsset,
    this.size = 42,
    this.radius = 15,
    this.fontSize = 14,
  });

  final String initials;
  final String? imageUrl;

  /// Shown when [imageUrl] is empty — e.g. the bundled profile placeholder
  /// for a user who hasn't uploaded a picture. Falls back to [initials] when
  /// null.
  final String? placeholderAsset;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final initialsBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCFE0B6), Color(0xFF8CA773)],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: PP.forest,
        ),
      ),
    );
    final fallback = placeholderAsset == null
        ? initialsBox
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.asset(
              placeholderAsset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => initialsBox,
            ),
          );
    final url = imageUrl;
    if (url == null || url.isEmpty || !url.startsWith('http')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, _, _) => fallback,
      ),
    );
  }
}

/// iOS-style toggle switch matching the design.
class PPToggle extends StatelessWidget {
  const PPToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? PP.forest : PP.inkA(0.16),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PP.inkA(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft-shadow white card container.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 32,
    this.color = PP.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// The status-bar-safe screen shell with the bone background.
class Screen extends StatelessWidget {
  const Screen({
    super.key,
    required this.child,
    this.background = PP.bone,
    this.bottomNav,
    this.floatingAction,
    this.extendBehindNav = false,
  });

  final Widget child;
  final Color background;
  final Widget? bottomNav;
  final Widget? floatingAction;
  final bool extendBehindNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      extendBody: true,
      body: child,
      bottomNavigationBar: bottomNav,
      floatingActionButton: floatingAction,
    );
  }
}
