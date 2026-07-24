import 'package:flutter/material.dart';

/// 자식 스크롤 영역을 감싸고, 일정 이상 내리면 우하단에
/// "맨 위로" 플로팅 버튼을 띄운다.
/// builder로 전달되는 ScrollController를 자식 스크롤 위젯에 연결해야 한다.
class ScrollTopArea extends StatefulWidget {
  const ScrollTopArea({super.key, required this.builder});

  final Widget Function(ScrollController controller) builder;

  @override
  State<ScrollTopArea> createState() => _ScrollTopAreaState();
}

class _ScrollTopAreaState extends State<ScrollTopArea> {
  final _controller = ScrollController();
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _controller.hasClients && _controller.offset > 800;
    if (show != _show) setState(() => _show = show);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.builder(_controller),
        Positioned(
          right: 16,
          bottom: 20,
          child: IgnorePointer(
            ignoring: !_show,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              scale: _show ? 1 : 0,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: '맨 위로',
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: () => _controller.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                ),
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
