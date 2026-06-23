import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../mock/mock_broadcasts.dart';
import '../models/broadcast.dart';
import 'hi.dart';
import '../core/theme/theme_controller.dart';

/// Bande défilante en haut du panneau — pannes, infos générales.
/// Non intrusive : ~24 px de haut, scroll continu droite→gauche.
class BroadcastBar extends StatefulWidget {
  final List<BroadcastMessage> messages;
  final double pxPerSecond;

  const BroadcastBar({
    super.key,
    this.messages = mockBroadcasts,
    this.pxPerSecond = 36,
  });

  @override
  State<BroadcastBar> createState() => _BroadcastBarState();
}

class _BroadcastBarState extends State<BroadcastBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final GlobalKey _firstCopyKey = GlobalKey();
  double? _singleWidth;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  void _measureAndStart() {
    final ctx = _firstCopyKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() => _singleWidth = box.size.width);
    final secs = (box.size.width / widget.pxPerSecond).clamp(8, 120);
    _ctrl.duration = Duration(milliseconds: (secs * 1000).round());
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    final items = _buildItems();
    return MouseRegion(
      onEnter: (_) {
        _paused = true;
        _ctrl.stop();
      },
      onExit: (_) {
        if (_paused) {
          _paused = false;
          _ctrl.repeat();
        }
      },
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Hi(AppIcons.megaphone, size: 13, color: AppColors.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    final w = _singleWidth ?? 0;
                    final offset = -_ctrl.value * w;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0, bottom: 0,
                          left: offset,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                key: _firstCopyKey,
                                mainAxisSize: MainAxisSize.min,
                                children: items,
                              ),
                              // 2ᵉ copie pour boucle sans saut visible
                              Row(mainAxisSize: MainAxisSize.min, children: items),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    final list = <Widget>[];
    for (final m in widget.messages) {
      list.add(_BroadcastItem(message: m));
      list.add(const _Separator());
    }
    return list;
  }
}

class _BroadcastItem extends StatelessWidget {
  final BroadcastMessage message;
  const _BroadcastItem({required this.message});

  Color _color() {
    switch (message.severity) {
      case BroadcastSeverity.info:
        return AppColors.info;
      case BroadcastSeverity.warning:
        return AppColors.warning;
      case BroadcastSeverity.danger:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            message.text,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        '•',
        style: TextStyle(color: P.muted, fontSize: 10),
      ),
    );
  }
}
