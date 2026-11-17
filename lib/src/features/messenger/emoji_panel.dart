import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';

/// The six reactions offered first, under a message.
const List<String> kQuickReactions = <String>['👍', '❤️', '😂', '😮', '😢', '🙏'];

const List<String> _smileys = <String>[
  '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋',
  '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '😮‍💨', '🤥', '😌',
  '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟',
  '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩', '😫',
  '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀', '💩', '🤡', '👻', '👽', '🤖',
];

const List<String> _gestures = <String>[
  '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖', '👋', '🤝', '👏',
  '🙌', '👐', '🤲', '🙏', '✍️', '💪', '🫶', '🫡', '🤌', '🤏',
];

const List<String> _hearts = <String>[
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💯', '💢',
  '💥', '💫', '💦', '💨', '🔥', '⭐', '🌟', '✨', '⚡', '🎉', '🎊', '🎁', '🏆', '🥇',
];

const List<String> _things = <String>[
  '🏠', '🏡', '🏢', '🏬', '🔑', '🚪', '🛏️', '🛋️', '🚿', '🛁', '🍽️', '🍳', '☕', '🍕', '🍔', '🍟', '🍎', '🍌', '🍉', '🍰',
  '🚗', '🚕', '🚌', '🏍️', '✈️', '🚀', '📍', '🗺️', '📱', '💻', '📷', '🎧', '💡', '💰', '💳', '📅', '📎', '📌', '✅', '❌',
  '⚠️', '❓', '❗', '🌍', '🌴', '🌞', '🌧️', '🌈',
];

/// A scrollable grid of emoji. [onPick] gets the one that was tapped.
class EmojiPanel extends StatelessWidget {
  const EmojiPanel({super.key, required this.onPick, this.height = 260});

  final ValueChanged<String> onPick;
  final double height;

  static const List<(String, List<String>)> _sections = <(String, List<String>)>[
    ('Smileys', _smileys),
    ('Gestures', _gestures),
    ('Hearts and symbols', _hearts),
    ('Home and things', _things),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      height: height,
      color: pal.panel,
      child: CustomScrollView(
        slivers: <Widget>[
          for (final (title, items) in _sections) ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 46, mainAxisExtent: 44),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onPick(items[i]),
                    child: Center(child: Text(items[i], style: const TextStyle(fontSize: 26))),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

/// Opens the full list of emoji in a sheet and returns the one chosen, or null.
Future<String?> pickEmoji(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => EmojiPanel(height: 340, onPick: (e) => Navigator.of(ctx).pop(e)),
  );
}
