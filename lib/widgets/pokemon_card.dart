import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;
  final Animation<double> animation;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.onTap,
    required this.animation,
  });

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard>
    with TickerProviderStateMixin {
  // ================= UI State =================
  bool _hover = false;
  Offset _dragOffset = Offset.zero;

  // ================= Controllers =================
  late final AnimationController _floatController;
  late final AnimationController _rotateController;

  // physics (ต้อง unbounded)
  late final AnimationController _springX;
  late final AnimationController _springY;

  // ================= Physics Config =================
  static const SpringDescription _jellySpring = SpringDescription(
    mass: 0.8,
    stiffness: 200,
    damping: 12,
  );

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _springX = AnimationController.unbounded(vsync: this);
    _springY = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _springX.dispose();
    _springY.dispose();
    super.dispose();
  }

  // ================= Gesture =================
  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;

    _springX.animateWith(
      SpringSimulation(_jellySpring, _dragOffset.dx, 0, v.dx),
    );

    _springY.animateWith(
      SpringSimulation(_jellySpring, _dragOffset.dy, 0, v.dy),
    );

    _dragOffset = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Pokemon.typeColor(widget.pokemon.types.first);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - widget.animation.value)),
          child: Opacity(opacity: widget.animation.value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hover = true);
          _rotateController.repeat();
        },
        onExit: (_) {
          setState(() => _hover = false);
          _rotateController.stop();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: _hover
              ? (Matrix4.identity()
                  ..translate(0.0, -6.0)
                  ..scale(1.06))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: primary.withOpacity(_hover ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: _hover ? 16 : 8,
                offset: Offset(0, _hover ? 8 : 4),
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header =====
                  Text(
                    '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primary.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    widget.pokemon.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // ===== Pokémon Image =====
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _floatController,
                        _rotateController,
                        _springX,
                        _springY,
                      ]),
                      builder: (context, child) {
                        final floatY = -6 * sin(_floatController.value * pi);

                        return Transform.translate(
                          offset: Offset(
                            _dragOffset.dx + _springX.value,
                            _dragOffset.dy + _springY.value + floatY,
                          ),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_rotateController.value * 2 * pi),
                            child: child,
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'pokemon-${widget.pokemon.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.pokemon.imageUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ===== Controls =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          _floatController.repeat(reverse: true);
                          _rotateController.repeat();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () {
                          _floatController.stop();
                          _rotateController.stop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          _floatController.reset();
                          _rotateController.reset();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
