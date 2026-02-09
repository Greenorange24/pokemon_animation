import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';

/// Card แสดง Pokémon พร้อม staggered animation
/// รับ Animation<double> จาก parent เพื่อควบคุม slide-in + fade-in
class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final Animation<double> animation;
  final VoidCallback onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.animation,
    required this.onTap,
  });

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard>
    with TickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - widget.animation.value)),
          child: Opacity(opacity: widget.animation.value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovering = true);
          _rotationController.repeat();
        },
        onExit: (_) {
          setState(() => _isHovering = false);
          _rotationController.stop();
        },
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(
            begin: Offset.zero,
            end: _isHovering ? const Offset(0, -5) : Offset.zero,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(offset: offset, child: child);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _isHovering ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final primaryColor = Pokemon.typeColor(widget.pokemon.types.first);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _isHovering
              ? primaryColor.withOpacity(0.25)
              : primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovering
                ? primaryColor.withOpacity(0.6)
                : primaryColor.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            // Background Pokéball watermark
            Positioned(
              bottom: -15,
              right: -15,
              child: Icon(
                Icons.catching_pokemon,
                size: 80,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID
                  Text(
                    '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor.withOpacity(0.6),
                    ),
                  ),
                  // Name
                  Text(
                    widget.pokemon.name[0].toUpperCase() +
                        widget.pokemon.name.substring(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Type badges
                  Wrap(
                    spacing: 4,
                    children: widget.pokemon.types.map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Pokemon.typeColor(type),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  // Hero image with square path animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        // Square path: Left → Up → Right → Down → Left → repeat
                        double offsetX = 0;
                        double offsetY = 0;

                        if (!_isHovering) {
                          offsetX = 0;
                          offsetY = 0;
                        } else {
                          final progress = _rotationController.value;

                          if (progress < 0.2) {
                            // Move left
                            offsetX = -8 * (progress / 0.2);
                            offsetY = 0;
                          } else if (progress < 0.4) {
                            // Move up
                            offsetX = -8;
                            offsetY = -8 * ((progress - 0.2) / 0.2);
                          } else if (progress < 0.6) {
                            // Move right
                            offsetX = -8 + 16 * ((progress - 0.4) / 0.2);
                            offsetY = -8;
                          } else if (progress < 0.8) {
                            // Move down
                            offsetX = 8;
                            offsetY = -8 + 8 * ((progress - 0.6) / 0.2);
                          } else {
                            // Move left again
                            offsetX = 8 - 8 * ((progress - 0.8) / 0.2);
                            offsetY = 0;
                          }
                        }

                        return Transform.translate(
                          offset: Offset(offsetX, offsetY),
                          child: child,
                        );
                      },
                      child: Hero(
                        tag: 'pokemon-${widget.pokemon.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.pokemon.imageUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.catching_pokemon, size: 60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
