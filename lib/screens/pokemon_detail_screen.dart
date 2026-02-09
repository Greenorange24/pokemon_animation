import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../widgets/pokemon_stats.dart';

/// หน้ารายละเอียด Pokémon
/// Animation ที่ใช้:
/// - Hero (รูปภาพ Pokémon)
/// - SlideTransition + FadeTransition (bottom sheet เลื่อนขึ้น)
/// - Rotating Pokéball background decoration
/// - Staggered stat bars (ใน PokemonStats widget)
class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade in delayed (เพื่อให้ Hero animation เล่นจบก่อน)
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.3, 1.0)),
    );

    // Slide up bottom sheet
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final primaryColor = Pokemon.typeColor(pokemon.types.first);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Background Pokéball decoration (หมุนช้าๆ)
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _fadeController.value * 0.5,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.catching_pokemon,
                      size: 250,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Column(
            children: [
              // Top section: back button + name + type + Hero image
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Custom app bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BackButton(onPressed: () => Navigator.pop(context)),
                          Text(
                            '#${pokemon.id.toString().padLeft(3, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Name
                      Text(
                        pokemon.name[0].toUpperCase() +
                            pokemon.name.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Type badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: pokemon.types.map((type) {
                          return _TypeBadge(type: type);
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Hero image with hover animation
                      _PokemonImage(pokemon: pokemon),
                    ],
                  ),
                ),
              ),

              // Bottom sheet with stats (slide up + fade in)
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Physical info (height/weight)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _InfoItemCard(
                                  label: 'Weight',
                                  value: '${pokemon.weight} kg',
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                _InfoItemCard(
                                  label: 'Height',
                                  value: '${pokemon.height} m',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Animated stat bars
                            PokemonStats(pokemon: pokemon),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Info item card with hover animation
class _InfoItemCard extends StatefulWidget {
  final String label;
  final String value;

  const _InfoItemCard({required this.label, required this.value});

  @override
  State<_InfoItemCard> createState() => _InfoItemCardState();
}

class _InfoItemCardState extends State<_InfoItemCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(
          begin: Offset.zero,
          end: _isHovering ? const Offset(0, -4) : Offset.zero,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, offset, child) {
          return Transform.translate(offset: offset, child: child);
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: _isHovering ? Colors.black87 : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          child: Column(
            children: [
              Text(widget.value),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _isHovering
                      ? Colors.grey.shade800
                      : Colors.grey.shade600,
                  fontWeight: _isHovering ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type badge widget พร้อม hover animation
class _TypeBadge extends StatefulWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  State<_TypeBadge> createState() => _TypeBadgeState();
}

class _TypeBadgeState extends State<_TypeBadge> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(
          begin: Offset.zero,
          end: _isHovering ? const Offset(0, -3) : Offset.zero,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, offset, child) {
          return Transform.translate(offset: offset, child: child);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _isHovering ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _isHovering
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.type,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button with hover scale animation
class _BackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _isHovering ? 1.2 : 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: IconButton(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

/// Pokemon image with hover wobble animation
class _PokemonImage extends StatefulWidget {
  final Pokemon pokemon;

  const _PokemonImage({required this.pokemon});

  @override
  State<_PokemonImage> createState() => _PokemonImageState();
}

class _PokemonImageState extends State<_PokemonImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: _isHovering ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        builder: (context, animate, child) {
          // Bounce animation: เด้งขึ้นลง
          final bounce = sin(animate * pi) * 6;
          // Rotate animation: หมุนเล็กน้อย
          final rotation = animate * 0.3;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, -bounce)
              ..rotateZ(rotation),
            child: child,
          );
        },
        child: Hero(
          tag: 'pokemon-${widget.pokemon.id}',
          child: CachedNetworkImage(
            imageUrl: widget.pokemon.imageUrl,
            height: 200,
            width: 200,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) => const Icon(
              Icons.catching_pokemon,
              size: 120,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
