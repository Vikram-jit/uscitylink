import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// Design kit for the staff / admin side of the app.
///
/// Built on the same tokens as the redesigned driver dashboard (AppSpacing, AppRadii, AppShadows,
/// AppGradients, AppText) so both halves read as one product, but everything here is staff-only:
/// driver screens never import this file, and the shared `TColors.primaryStaff` (still used by a
/// few driver screens) is left untouched.
class StaffColors {
  StaffColors._();

  /// Buttons, accents, app bars and the active tab — the brand navy from the logo.
  static const Color primary = TColors.navyHeaderDeep;
  static const Color ink = TColors.navyHeader;
  static const Color canvas = TColors.surfaceCanvas;
  static const Color card = TColors.surfaceCard;
  static const Color hairline = TColors.hairline;
  static const Color textStrong = TColors.textStrong;
  static const Color textBody = TColors.textBody;
  static const Color textMuted = TColors.textMuted;
  static const Color success = TColors.brandGreen;
  static const Color danger = TColors.brandRed;
  static const Color warning = TColors.brandGold;

  /// Tile accents — each section of the dashboard keeps one hue so it is recognisable at a glance.
  static const Color violet = TColors.violet;
  static const Color teal = TColors.teal;
  static const Color orange = TColors.alertOrange;
  static const Color sky = Color(0xFF2563EB);

  static const LinearGradient header = AppGradients.header;
}

/// Light status-bar icons over the dark gradient header.
const SystemUiOverlayStyle kStaffOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// Gradient page header used by the main staff tabs (Chats, Group chats, Channels).
/// [bottom] sits inside the gradient (search field, tabs).
class StaffHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final List<Widget> actions;
  final Widget? bottom;

  const StaffHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon = Icons.menu_rounded,
    this.onLeading,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: StaffColors.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        topInset + AppSpacing.sm,
        AppSpacing.base,
        bottom == null ? AppSpacing.lg : AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StaffGlassButton(icon: leadingIcon, onTap: onLeading),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.headline.copyWith(color: Colors.white),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.base),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Square translucent icon button that sits on the gradient (menu, back, actions).
class StaffGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const StaffGlassButton({super.key, required this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// White rounded search field for use on the gradient header.
class StaffSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const StaffSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppText.bodyMd.copyWith(color: StaffColors.textStrong),
        cursorColor: StaffColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.bodyMd.copyWith(color: StaffColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: StaffColors.textMuted, size: 22),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Pill-style tab bar for the gradient header (white pill = selected tab).
class StaffSegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const StaffSegmentedTabs({super.key, required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.sm - 4),
        ),
        labelColor: StaffColors.primary,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
        labelStyle: AppText.labelLg,
        unselectedLabelStyle: AppText.labelLg,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [for (final l in labels) Tab(text: l)],
      ),
    );
  }
}

/// Initials avatar with a stable colour per name and an optional online dot.
class StaffAvatar extends StatelessWidget {
  final String? name;
  final bool online;
  final IconData? icon;
  final double size;

  const StaffAvatar({super.key, this.name, this.online = false, this.icon, this.size = 48});

  static const _palette = [
    Color(0xFF1B3B8C),
    Color(0xFF0B5D53),
    Color(0xFF5B34C4),
    Color(0xFFB45309),
    Color(0xFF0E7490),
    Color(0xFFBE185D),
    Color(0xFF4D7C0F),
  ];

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[(name ?? '').codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.32),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: color, size: size * 0.48)
                : Text(
                    initials(name),
                    style: AppText.titleMd.copyWith(color: color, fontSize: size * 0.34),
                  ),
          ),
          if (online)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: StaffColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Unread count badge (hidden when zero).
class StaffCountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const StaffCountBadge({super.key, required this.count, this.color = StaffColors.primary});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.pill)),
      // Center with width/height factors sizes to the text. (Container.alignment would stretch to
      // fill the space it is given, e.g. the whole tile width as a ListTile trailing widget.)
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppText.numeric(AppText.labelSm).copyWith(color: Colors.white, letterSpacing: 0),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. "Truck 24565", "Admin", "Active".
class StaffPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const StaffPill({super.key, required this.label, this.color = StaffColors.primary, this.icon, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelMd.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversation / group row as a white card. Optional swipe-to-delete via [onDismissed].
class StaffListCard extends StatelessWidget {
  final Key dismissKey;
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? time;
  final int unread;
  final List<Widget> chips;
  final VoidCallback onTap;
  final DismissDirectionCallback? onDismissed;

  const StaffListCard({
    super.key,
    required this.dismissKey,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.time,
    this.unread = 0,
    this.chips = const [],
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: StaffColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.titleMd.copyWith(color: StaffColors.textStrong),
                          ),
                        ),
                        if (time != null && time!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: Text(
                              time!,
                              style: AppText.labelMd.copyWith(
                                color: unread > 0 ? StaffColors.primary : StaffColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 4, children: chips),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm.copyWith(
                              color: unread > 0 ? StaffColors.textBody : StaffColors.textMuted,
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          StaffCountBadge(count: unread),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final framed = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.md), boxShadow: AppShadows.card),
      child: card,
    );

    if (onDismissed == null) return framed;
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: StaffColors.danger,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: framed,
    );
  }
}

/// Section title with an optional action link, e.g. "Team channels".
class StaffSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StaffSectionTitle({super.key, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
              if (subtitle != null)
                Text(subtitle!, style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: StaffColors.primary, padding: EdgeInsets.zero),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!, style: AppText.labelLg),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

/// Dashboard tile: tinted icon, big number, label. Tappable.
class StaffStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String? caption;
  final VoidCallback onTap;

  const StaffStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.lg), boxShadow: AppShadows.card),
      child: Material(
        color: StaffColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_outward_rounded, size: 18, color: StaffColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$value',
                  style: AppText.numeric(AppText.displaySm).copyWith(color: StaffColors.textStrong),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(color: StaffColors.textBody),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelMd.copyWith(color: StaffColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered message for empty lists.
class StaffEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const StaffEmptyState({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh still works on an empty list
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 80),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: StaffColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Icon(icon, color: StaffColors.primary, size: 34),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(title, textAlign: TextAlign.center, style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(message!, textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: StaffColors.textMuted)),
        ],
      ],
    );
  }
}

/// Primary floating action button in the staff navy.
class StaffFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Object heroTag;

  const StaffFab({super.key, required this.label, required this.icon, required this.onPressed, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: StaffColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: AppText.labelLg.copyWith(color: Colors.white)),
    );
  }
}

String staffGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String staffRoleLabel(String? role) {
  final r = (role ?? '').trim().toLowerCase();
  if (r == 'admin') return 'Admin';
  if (r == 'staff') return 'Dispatcher';
  return r.isEmpty ? 'Staff' : '${r[0].toUpperCase()}${r.substring(1)}';
}
