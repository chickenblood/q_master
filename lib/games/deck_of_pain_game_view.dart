import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/deck_of_pain.dart';
import 'package:q_master/model/pain_card.dart';
import 'package:q_master/ui/adaptive_icons.dart';

final class DeckOfPainGameView extends StatelessWidget {
  final String heroTag;

  const DeckOfPainGameView({super.key, this.heroTag = ''});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Object() /* ignore heroTag for now */,
      child: PlatformScaffold(
        iosContentPadding: true, // Fixes app bar underlap for landscape.
        backgroundColor: Colors.black,
        appBar: PlatformAppBar(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: PlatformText(
            L10n.of(context)!.dopGameScreenTitle,
            style: TextStyle(color: Colors.white),
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

final class _Deck extends ConsumerStatefulWidget {
  const _Deck();

  @override
  _DeckState createState() => _DeckState();
}

class _DeckState extends ConsumerState<_Deck> with TickerProviderStateMixin {
  // Always maintain exactly 2 cards in the stack
  PainCard? _topCard;
  PainCard? _bottomCard;
  bool _topCardFlipped = true; // true = face down
  bool _bottomCardFlipped = true;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
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
    final notifier = ref.read(deckOfPainProvider.notifier);
    _topCard = notifier.currentCard();
    _bottomCard = notifier.nextCard();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onSlideComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        // Move bottom card to top position (keep it face down)
        _topCard = _bottomCard;
        _topCardFlipped = true; // Ensure revealed card is face down

        // Draw new bottom card
        final notifier = ref.read(deckOfPainProvider.notifier);
        _bottomCard = notifier.drawCard();
        _bottomCardFlipped = true; // New bottom card is face down

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
    ref.watch(deckOfPainProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom card - always present, offset slightly
          if (_bottomCard != null)
            Transform.translate(
              offset: Offset(0, -0),
              child: _CardFlipView(
                isFlipped: _bottomCardFlipped,
                shouldAnimate:
                    true, // Enable animation so it can flip when revealed
                front: _FrontCardView(painCard: _bottomCard!),
                back: const _BackCardView(),
              ),
            ),
          // Top card - interactive, slides off when tapped
          if (_topCard != null)
            SlideTransition(
              position: _slideAnimation,
              child: Material(
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.circular(16.0),
                child: InkWell(
                  onTap: _handleTap,
                  child: _CardFlipView(
                    isFlipped: _topCardFlipped,
                    shouldAnimate: true,
                    front: _FrontCardView(painCard: _topCard!),
                    back: const _BackCardView(),
                  ),
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
      style: style.copyWith(fontWeight: FontWeight.bold, color: color),
      textScaler: .noScaling,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    final textStyle = isLandscape
        ? TextTheme.of(context).displaySmall!
        : TextTheme.of(context).displayLarge!;
    return Container(
      color: Colors.white,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            fit: .expand,
            children: [
              Align(
                alignment: Alignment.center,
                child: PlatformText(
                  painCard.description,
                  textAlign: TextAlign.center,
                  overflow: .fade,
                  maxLines: 5,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: painCard.suit.color,
                  ),
                  textScaler: .noScaling,
                ),
              ),
              // Top left decoration
              Align(
                alignment: Alignment.topLeft,
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
              // Bottom right decoration
              Align(
                alignment: Alignment.bottomRight,
                child: Transform.rotate(
                  angle: pi, // Rotate 180 degrees
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
    child: AspectRatio(aspectRatio: 2 / 3),
  );
}

final class _CardFlipView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return isFlipped ? back : front;
  }
}
