import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/ui/media_query.dart';

import '../l10n/l10n.dart';
import '../model/deck_of_pain.dart';
import '../model/pain_card.dart';
import '../ui/adaptive_app_bar.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_scaffold.dart';

const _defaultDeckOfPainHeroTag = 'deck_of_pain_game';

final class DeckOfPainGameView extends StatelessWidget {
  final String heroTag;

  const DeckOfPainGameView({
    super.key,
    this.heroTag = _defaultDeckOfPainHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: AdaptiveScaffold(
        backgroundColor: Colors.black,
        appBar: AdaptiveAppBar(
          backgroundColor: Colors.transparent,
          leading: [
            AdaptiveAppBarItem(
              icon: Icon(AdaptiveIcons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          title: PlatformText(
            L10n.of(context)!.dopGameScreenTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
        body: Center(child: _Deck()),
      ),
    );
  }
}

final class _Deck extends StatefulWidget {
  @override
  _DeckState createState() => _DeckState();
}

class _DeckState extends State<_Deck> with TickerProviderStateMixin {
  final _deck = DeckOfPain();
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  // Always maintain exactly 2 cards in the stack
  PainCard? _topCard;
  PainCard? _bottomCard;
  bool _topCardFlipped = true; // true = face down

  bool _isSlidingOff = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation for sliding card off
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.5)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
    _slideController.addStatusListener(_onSlideComplete);

    // Initialize the two-card stack
    _topCard = _deck.currentCard();
    _bottomCard = _deck.nextCard();
  }

  @override
  void dispose() {
    _slideController.removeStatusListener(_onSlideComplete);
    _slideController.dispose();
    super.dispose();
  }

  void _onSlideComplete(AnimationStatus status) {
    if (status == .completed) {
      setState(() {
        // Move bottom card to top position (keep it face down)
        _topCard = _bottomCard;
        _topCardFlipped = true; // Ensure revealed card is face down

        _deck.drawCard();

        // Draw new bottom card
        _bottomCard = _deck.nextCard();

        // Reset slide animation
        _isSlidingOff = false;
        _slideController.reset();
      });

      // Auto-flip the newly revealed top card after a brief delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _topCardFlipped = false);
        }
      });
    }
  }

  void _handleTap() {
    if (_isSlidingOff) return;

    if (_topCardFlipped) {
      // Flip top card to reveal front
      setState(() => _topCardFlipped = false);
    } else {
      // Slide top card off to reveal bottom card
      setState(() => _isSlidingOff = true);
      _slideController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: .center,
        children: [
          // Revealed when last card is slid off and no more are available.
          if (_topCard == null || _bottomCard == null)
            PlatformText(
              L10n.of(context)!.dopAllDoneLabel,
              textAlign: .center,
              style: TextTheme.of(
                context,
              ).displayLarge!.copyWith(color: Colors.white),
              textScaler: .noScaling,
            ),
          if (_bottomCard != null)
            _CardFlipView(
              key: ValueKey(_bottomCard),
              isFlipped: true,
              shouldAnimate: false, // Don't animate until it becomes top card
              front: _FrontCardView(painCard: _bottomCard!),
              back: const _BackCardView(),
            ),
          // Top card - interactive, slides off when tapped
          if (_topCard != null)
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _handleTap,
                child: _CardFlipView(
                  key: ValueKey(_topCard),
                  isFlipped: _topCardFlipped,
                  shouldAnimate: true,
                  front: _FrontCardView(painCard: _topCard!),
                  back: const _BackCardView(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrontCardView extends StatelessWidget {
  final PainCard painCard;

  const _FrontCardView({required this.painCard});

  Widget _buildText(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required Color color,
  }) {
    return PlatformText(
      text,
      textAlign: .center,
      style: style.copyWith(fontWeight: .bold, color: color),
      textScaler: .noScaling,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    final isTablet = MediaUtils.isTablet(context);
    final textStyle = switch ((isLandscape, isTablet)) {
      (_, true) => TextTheme.of(context).displayLarge!.copyWith(fontSize: 96),
      (true, _) => TextTheme.of(context).displaySmall!,
      (false, _) => TextTheme.of(context).displayLarge!,
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.white,
      ),
      clipBehavior: .hardEdge,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Top left decoration
              Row(
                children: [
                  Column(
                    mainAxisSize: .min,
                    children: [
                      _buildText(
                        context,
                        text: painCard.displayName,
                        style: textStyle,
                        color: painCard.suit.color,
                      ),
                      _buildText(
                        context,
                        text: painCard.suit.symbol,
                        style: textStyle,
                        color: painCard.suit.color,
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: AutoSizeText(
                    painCard.description,
                    textAlign: .center,
                    overflow: .fade,
                    maxLines: 5,
                    minFontSize: 18,
                    style: textStyle.copyWith(
                      fontWeight: .bold,
                      color: painCard.suit.color,
                    ),
                  ),
                ),
              ),
              // Bottom right decoration
              Row(
                mainAxisAlignment: .end,
                children: [
                  Transform.rotate(
                    angle: pi,
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        _buildText(
                          context,
                          text: painCard.displayName,
                          style: textStyle,
                          color: painCard.suit.color,
                        ),
                        _buildText(
                          context,
                          text: painCard.suit.symbol,
                          style: textStyle,
                          color: painCard.suit.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCardView extends StatelessWidget {
  const _BackCardView();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.0),
      image: DecorationImage(
        image: AssetImage('assets/images/card_back.png'),
        repeat: .repeat,
        fit: .contain,
      ),
    ),
    clipBehavior: .hardEdge,
    child: AspectRatio(aspectRatio: 2 / 3),
  );
}

final class _CardFlipView extends StatefulWidget {
  final bool isFlipped;
  final bool shouldAnimate;
  final Widget front;
  final Widget back;

  const _CardFlipView({
    super.key,
    required this.isFlipped,
    required this.shouldAnimate,
    required this.front,
    required this.back,
  });

  @override
  State<_CardFlipView> createState() => _CardFlipViewState();
}

class _CardFlipViewState extends State<_CardFlipView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animator;

  @override
  void initState() {
    super.initState();
    _animator = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: pi,
      duration: const Duration(milliseconds: 400),
    );

    // Start with the correct side based on isFlipped
    _animator.value = widget.isFlipped ? 0 : pi;
  }

  @override
  void didUpdateWidget(covariant _CardFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (!widget.shouldAnimate) {
        // Snap immediately when animation is disabled for this card.
        _animator.value = widget.isFlipped ? 0 : pi;
        return;
      }

      // Set to current position and animate to target
      _animator.value = oldWidget.isFlipped ? 0 : pi;
      _animator.forward();
    }
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animator,
      builder: (context, child) {
        final progress = _animator.value;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Add perspective
            ..rotateY(pi + progress),
          alignment: .center,
          child: progress < pi / 2 ? widget.back : widget.front,
        );
      },
    );
  }
}
