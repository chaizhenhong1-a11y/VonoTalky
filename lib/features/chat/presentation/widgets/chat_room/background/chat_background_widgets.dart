part of '../../../pages/real_chat_room_page.dart';

class _BackgroundChoice extends StatelessWidget {
  const _BackgroundChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7653A5)
                      : const Color(0xFFD7D1DC),
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Color(0xFF7653A5))
                  : null,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ChatBackgroundSwitcher extends StatefulWidget {
  const _ChatBackgroundSwitcher({
    required this.otherName,
    required this.viewMode,
    required this.otherAvailable,
    required this.onToggle,
  });

  final String otherName;
  final ChatBackgroundViewMode viewMode;
  final bool otherAvailable;
  final VoidCallback onToggle;

  @override
  State<_ChatBackgroundSwitcher> createState() =>
      _ChatBackgroundSwitcherState();
}

class _ChatBackgroundSwitcherState
    extends State<_ChatBackgroundSwitcher> {
  Timer? _hintTimer;
  bool _showHint = false;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    final viewingOther =
        widget.viewMode == ChatBackgroundViewMode.other;

    if (viewingOther) {
      _hideHint();
      widget.onToggle();
      return;
    }

    if (!widget.otherAvailable) {
      _showUnavailableHint();
      return;
    }

    _hideHint();
    widget.onToggle();
  }

  void _showUnavailableHint() {
    _hintTimer?.cancel();

    if (!_showHint) {
      setState(() {
        _showHint = true;
      });
    }

    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _showHint = false;
      });
    });
  }

  void _hideHint() {
    _hintTimer?.cancel();

    if (!_showHint || !mounted) return;

    setState(() {
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewingOther =
        widget.viewMode == ChatBackgroundViewMode.other;

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _buildButton(
              colorScheme,
              viewingOther,
            ),
          ),

          Positioned(
            top: 50,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showHint ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _showHint
                      ? Offset.zero
                      : const Offset(0, -0.12),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _buildHint(colorScheme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    ColorScheme colorScheme,
    bool viewingOther,
  ) {
    return SizedBox(
      width: 132,
      height: 42,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: viewingOther
                  ? colorScheme.primaryContainer.withValues(alpha: 0.94)
                  : colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: viewingOther
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: viewingOther
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    viewingOther
                        ? Icons.person_rounded
                        : Icons.wallpaper_rounded,
                    size: 15,
                    color: viewingOther
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewingOther ? widget.otherName : 'Mine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: viewingOther
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: viewingOther
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint(ColorScheme colorScheme) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: colorScheme.onInverseSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.otherName} has not shared or set a background',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onInverseSurface,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}