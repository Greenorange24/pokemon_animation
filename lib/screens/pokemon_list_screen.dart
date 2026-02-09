import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/pokeball_spinner.dart';
import '../routes/pokemon_route.dart';
import 'pokemon_detail_screen.dart';

/// หน้าหลักแสดงรายการ Pokémon
/// Animation ที่ใช้:
/// - Shimmer Loading (ขณะโหลดข้อมูล)
/// - Staggered Grid Entry (card ปรากฏทีละใบ)
/// - AnimatedSwitcher (สลับ Grid/List view)
/// - Hero (ไปหน้า Detail)
/// - Custom Page Transition (PokemonPageRoute)
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen>
    with TickerProviderStateMixin {
  List<Pokemon> _pokemons = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String? _errorMessage;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadPokemons();
  }

  Future<void> _loadPokemons() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final pokemons = await PokemonService.fetchPokemonList(limit: 20);
      if (!mounted) return;
      setState(() {
        _pokemons = pokemons;
        _isLoading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถโหลดข้อมูลได้\n$e';
      });
    }
  }

  void _navigateToDetail(Pokemon pokemon) {
    Navigator.push(
      context,
      PokemonPageRoute(page: PokemonDetailScreen(pokemon: pokemon)),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon, size: 28),
            SizedBox(width: 8),
            Text('Pokédex', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          // Toggle Grid/List ด้วย AnimatedSwitcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: IconButton(
              key: ValueKey(_isGridView),
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PokeballSpinner(size: 60),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPokemons,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    // AnimatedSwitcher สลับระหว่าง Grid กับ List
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isGridView
          ? _buildGrid(key: const ValueKey('grid'))
          : _buildList(key: const ValueKey('list')),
    );
  }

  Widget _buildGrid({Key? key}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pokemons.length,
      itemBuilder: (context, index) {
        // Staggered animation: แต่ละ card เริ่ม animate ช้าลงตาม index
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              (index / _pokemons.length * 0.6).clamp(0.0, 1.0),
              ((index / _pokemons.length * 0.6) + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        return PokemonCard(
          pokemon: _pokemons[index],
          animation: animation,
          onTap: () => _navigateToDetail(_pokemons[index]),
        );
      },
    );
  }

  Widget _buildList({Key? key}) {
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.all(16),
      itemCount: _pokemons.length,
      itemBuilder: (context, index) {
        final pokemon = _pokemons[index];
        return _PokemonListItem(
          pokemon: pokemon,
          onTap: () => _navigateToDetail(pokemon),
        );
      },
    );
  }
}

/// ListTile item สำหรับ ListView พร้อม hover bounce and color animation
class _PokemonListItem extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const _PokemonListItem({required this.pokemon, required this.onTap});

  @override
  State<_PokemonListItem> createState() => _PokemonListItemState();
}

class _PokemonListItemState extends State<_PokemonListItem>
    with TickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _wobbleController;
  late AnimationController _springController;
  Offset _dragOffset = Offset.zero;
  Offset _springOffset = Offset.zero;
  bool _enable3DRotation = false;
  bool _isAnimationPlaying = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _springController = AnimationController(vsync: this);
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _springController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = Offset(details.globalPosition.dx, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final springSimulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 100.0,
        ratio: 0.6,
      ),
      _dragOffset.dx,
      0,
      details.velocity.pixelsPerSecond.dx / 1000,
    );
    _springController.animateWith(springSimulation).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _springOffset = Offset.zero;
      });
    });
  }

  void _toggleAnimation() {
    if (_isAnimationPlaying) {
      _rotationController.stop();
      setState(() => _isAnimationPlaying = false);
    } else {
      _rotationController.repeat();
      setState(() => _isAnimationPlaying = true);
    }
  }

  void _pauseAnimation() {
    _rotationController.stop();
    setState(() => _isAnimationPlaying = false);
  }

  void _stopAnimation() {
    _rotationController.reset();
    setState(() => _isAnimationPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _wobbleController.repeat();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _wobbleController.stop();
      },
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: _isHovering ? Colors.grey.shade100 : Colors.white,
            child: ListTile(
              onTap: widget.onTap,
              leading: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _wobbleController,
                      _springController,
                      _rotationController,
                    ]),
                    builder: (context, child) {
                      // Drag spring animation
                      _springOffset = Offset(
                        _springController.value * (_dragOffset.dx - 0),
                        0,
                      );

                      if (!_isHovering) {
                        return child!;
                      }

                      // Wobble animation: เดินซ้ายขวา loop ไปเรื่อยๆ
                      final wobble = (_wobbleController.value * pi * 2);
                      final offsetX = 8 * cos(wobble);
                      final offsetY =
                          -2 * (sin(_wobbleController.value * pi).abs());
                      final scale =
                          1.0 + (sin(_wobbleController.value * pi).abs()) * 0.15;

                      // 3D Rotation
                      final rotationValue = _enable3DRotation
                          ? _rotationController.value
                          : 0.0;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(
                            offsetX + _dragOffset.dx + _springOffset.dx,
                            offsetY,
                          )
                          ..scale(scale)
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(rotationValue * pi * 2),
                        child: child,
                      );
                    },
                    child: Hero(
                      tag: 'pokemon-${widget.pokemon.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.pokemon.imageUrl,
                        width: 50,
                        height: 50,
                        placeholder: (_, __) => const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.catching_pokemon, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'play') _toggleAnimation();
                  if (value == 'pause') _pauseAnimation();
                  if (value == 'stop') _stopAnimation();
                  if (value == '3d') {
                    setState(() => _enable3DRotation = !_enable3DRotation);
                    if (_enable3DRotation && !_isAnimationPlaying) {
                      _toggleAnimation();
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        Icon(
                          _isAnimationPlaying
                              ? Icons.play_arrow
                              : Icons.play_circle_outline,
                        ),
                        const SizedBox(width: 8),
                        const Text('Play'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pause',
                    child: Row(
                      children: [
                        Icon(
                          _isAnimationPlaying
                              ? Icons.pause_circle_outline
                              : Icons.pause,
                        ),
                        const SizedBox(width: 8),
                        const Text('Pause'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'stop',
                    child: Row(
                      children: [
                        const Icon(Icons.stop_circle_outlined),
                        const SizedBox(width: 8),
                        const Text('Stop'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: '3d',
                    child: Row(
                      children: [
                        Icon(
                          _enable3DRotation
                              ? Icons.threed_rotation
                              : Icons.three_k,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _enable3DRotation ? 'Disable 3D' : 'Enable 3D',
                        ),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: _enable3DRotation ? Colors.blue : Colors.grey,
                ),
              ),
              title: Text(
                widget.pokemon.name[0].toUpperCase() +
                    widget.pokemon.name.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
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
