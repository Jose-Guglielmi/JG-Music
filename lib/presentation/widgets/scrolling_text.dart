import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool centerWhenNoScroll;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.centerWhenNoScroll = false,
  });

  @override
  ScrollingTextState createState() => ScrollingTextState();
}

class ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _maxOffset = 0.0;
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForOverflow());
  }

  @override
  void didUpdateWidget(ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForOverflow());
    }
  }

  void _checkForOverflow() {
    setState(() {
      final textPainter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: double.infinity);

      _maxOffset = textPainter.width - context.size!.width;
      _hasOverflow = _maxOffset > 0;

      if (_hasOverflow) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: (widget.style.fontSize != null)
              ? widget.style.fontSize! + 10
              : 30,
          child: _hasOverflow ? _buildScrollingText() : _buildStaticText(),
        );
      },
    );
  }

  Widget _buildStaticText() {
    return Align(
      alignment:
          widget.centerWhenNoScroll ? Alignment.center : Alignment.centerLeft,
      child: Text(
        widget.text,
        style: widget.style,
        textAlign:
            widget.centerWhenNoScroll ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildScrollingText() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            double offset = _animationController.value * _maxOffset;
            _scrollController.jumpTo(offset);
          }
        });
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
