import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/appearance_options.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/pattern_painter.dart';
import '../../core/widgets/widgets.dart';
import '../../state/appearance_controller.dart';

/// Theme, font and corner controls. Used on the Appearance page and in the sheet that
/// signed-out screens open, so the look can be changed before signing in.
class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key});

  void _pickTheme(BuildContext context, WidgetRef ref, String id, Offset origin) {
    final notifier = ref.read(appearanceProvider.notifier);
    final reveal = ThemeReveal.maybeOf(context);
    if (reveal == null) {
      notifier.setTheme(id);
    } else {
      reveal.run(origin, () => notifier.setTheme(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CurrentLook(look: look),
        SectionHeader('Theme (${AppPalette.all.length})', padding: const EdgeInsets.only(top: 24, bottom: 6)),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'The new theme opens from the point you tap. On a computer, press T to step through themes and Shift+T to go back.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: context.mutedColor),
          ),
        ),
        ResponsiveWrap(
          minItemWidth: 190,
          maxColumns: 4,
          children: <Widget>[
            _ThemeCard(
              title: 'Match device',
              note: 'Premisave, light or night to suit your phone',
              selected: look.isAuto,
              preview: const Row(
                children: <Widget>[
                  Expanded(child: _Preview(palette: AppPalette.premisave)),
                  Expanded(child: _Preview(palette: AppPalette.premisaveNight)),
                ],
              ),
              onSelect: (origin) => _pickTheme(context, ref, Appearance.auto, origin),
            ),
            for (final p in AppPalette.all)
              _ThemeCard(
                title: p.name,
                note: p.note,
                selected: look.themeId == p.id,
                preview: _Preview(palette: p),
                onSelect: (origin) => _pickTheme(context, ref, p.id, origin),
              ),
          ],
        ),
        const SectionHeader('Font'),
        ResponsiveWrap(
          minItemWidth: 230,
          maxColumns: 3,
          children: <Widget>[
            for (final f in FontOption.all)
              _FontCard(option: f, selected: look.fontId == f.id, onSelect: () => notifier.setFont(f.id)),
          ],
        ),
        const SectionHeader('Corners'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: <ButtonSegment<String>>[
              for (final c in CornerOption.all) ButtonSegment<String>(value: c.id, label: Text(c.name)),
            ],
            selected: <String>{look.cornerId},
            onSelectionChanged: (s) => notifier.setCorner(s.first),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: PButton(
            label: 'Reset appearance',
            icon: Icons.restart_alt_rounded,
            kind: PButtonKind.outline,
            small: true,
            onPressed: notifier.reset,
          ),
        ),
      ],
    );
  }
}

/// Palette icon that opens the appearance sheet. Put it on any screen, signed in or not.
class AppearanceButton extends StatelessWidget {
  const AppearanceButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Appearance',
      icon: Icon(Icons.palette_outlined, color: color),
      onPressed: () => showAppearanceSheet(context),
    );
  }
}

Future<void> showAppearanceSheet(BuildContext context) {
  return showCenteredSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: context.surfaceColor,
    constraints: const BoxConstraints(maxWidth: 820),
    builder: (_) => const _AppearanceSheet(),
  );
}

/// The appearance controls in a sheet that can be dragged taller, shorter or away. The header and the Close
/// button stay in view, and the drag works with a mouse as well as a finger.
class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  static const Set<PointerDeviceKind> _dragDevices = <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, controller) => ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: _dragDevices),
        child: Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                controller: controller,
                slivers: const <Widget>[
                  SliverPersistentHeader(pinned: true, delegate: _HeaderDelegate()),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverToBoxAdapter(child: AppearancePicker()),
                  ),
                ],
              ),
            ),
            const _SheetFooter(),
          ],
        ),
      ),
    );
  }
}

/// Grab handle, title and a close button. It is part of the scroll view, so dragging it moves the whole sheet.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate();

  static const double _height = 96;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final pal = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: overlapsContent ? context.borderColor : Colors.transparent)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: pal.line2, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const IconBadge(Icons.palette_outlined, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Appearance', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.display(size: 19, weight: FontWeight.w800, spacing: -0.4)),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a theme, font and corner style.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: context.mutedColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Close button pinned under the scrolling controls.
class _SheetFooter extends StatelessWidget {
  const _SheetFooter();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Changes apply straight away and are saved on this device.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: context.mutedColor),
                ),
              ),
              const SizedBox(width: 14),
              PButton(label: 'Close', icon: Icons.close_rounded, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short summary of the look in use now: the theme with its colours, the font and the corner style.
class _CurrentLook extends StatelessWidget {
  const _CurrentLook({required this.look});

  final Appearance look;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      color: pal.accentSoft,
      borderColor: pal.accent.op(0.25),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Your current look', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              for (final c in <Color>[pal.accent, pal.good, pal.warn, pal.bad])
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: pal.line2)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LookChip(icon: Icons.palette_outlined, label: look.palette?.name ?? 'Match device'),
              _LookChip(icon: Icons.text_fields_rounded, label: look.font.name),
              _LookChip(icon: Icons.rounded_corner_rounded, label: '${look.corner.name} corners'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LookChip extends StatelessWidget {
  const _LookChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: pal.panel, borderRadius: BorderRadius.circular(99), border: Border.all(color: pal.line2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: pal.accent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Miniature of a theme: page colour and texture, a panel, and three swatches.
class _Preview extends StatelessWidget {
  const _Preview({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return SizedBox(
      height: 96,
      child: AppBackdrop(
        palette: p,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: p.panel,
                  border: Border.all(color: p.line2),
                  borderRadius: BorderRadius.circular(context.radius(4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(height: 5, width: 54, color: p.line2),
                    const SizedBox(height: 5),
                    Container(height: 5, width: 34, color: p.ink3),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: <Widget>[
                    for (final c in <Color>[p.accent, p.good, p.warn, p.bad])
                      Expanded(
                        child: Container(
                          height: 12,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(color: c, border: Border.all(color: p.line2)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.title,
    required this.note,
    required this.selected,
    required this.preview,
    required this.onSelect,
  });

  final String title;
  final String note;
  final bool selected;
  final Widget preview;
  final void Function(Offset origin) onSelect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.radius(Brand.radius));
    return Semantics(
      button: true,
      selected: selected,
      label: '$title theme',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onSelect(d.globalPosition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: radius,
              border: Border.all(color: selected ? context.pal.accent : context.borderColor, width: selected ? 2.2 : 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    preview,
                    if (selected) const Positioned(top: 8, right: 8, child: _CheckBadge()),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.3, color: context.mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round tick shown on the theme that is in use.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle, border: Border.all(color: pal.accentInk, width: 2)),
      child: Icon(Icons.check_rounded, size: 14, color: pal.accentInk),
    );
  }
}

class _FontCard extends StatelessWidget {
  const _FontCard({required this.option, required this.selected, required this.onSelect});

  final FontOption option;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.radius(Brand.radius));
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.name} font',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: radius,
              border: Border.all(color: selected ? context.pal.accent : context.borderColor, width: selected ? 2.2 : 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Find a place',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: option.display, fontSize: 23, height: 1.15, fontWeight: FontWeight.w700, color: context.inkColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified owners and a secure sign in, 0123456789',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: option.sans, fontSize: 13, height: 1.35, color: context.pal.ink2),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
                  child: Row(
                    children: <Widget>[
                      Text(option.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: context.mutedColor))),
                      if (selected) Icon(Icons.check_circle_rounded, size: 17, color: context.pal.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
