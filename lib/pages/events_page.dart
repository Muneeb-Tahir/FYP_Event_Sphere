import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/reaction_service.dart';
import '../services/bookmark_service.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> with TickerProviderStateMixin {
  Map<String, ReactionType> _userReactions = {}; // eventId → like/dislike
  Set<String> _bookmarkedEventIds = {}; // Track bookmarked events
  String? _userId;

  // Page controller for featured carousel
  late PageController _featuredPageController;
  int _currentFeaturedIndex = 0;
  Timer? _autoScrollTimer;

  List<Event>? _events;
  bool _isLoading = true;

  StreamSubscription? _eventsSubscription;
  StreamSubscription? _reactionsSubscription;

  // Debounce & lock for reaction toggling
  final Map<String, Timer> _reactionDebounceTimers = {};
  final Set<String> _processingReactions = {};
  Timer? _reloadDebounce;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // Particles for background effects
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();


  @override
  void initState() {
    super.initState();
    _initParticles();
    _featuredPageController = PageController(viewportFraction: 0.88);
    _loadReactions();
    _loadBookmarks();
    _loadEvents();
    _setupRealTimeSubscription();
    _startAutoScroll();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 3,
        speed: 0.2 + _random.nextDouble() * 0.4,
        opacity: 0.2 + _random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void dispose() {
    _featuredPageController.dispose();
    _autoScrollTimer?.cancel();
    _fadeController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _eventsSubscription?.cancel();
    _reactionsSubscription?.cancel();
    _reloadDebounce?.cancel();
    for (final t in _reactionDebounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_events != null && _events!.isNotEmpty && mounted) {
        // Only auto-scroll if the controller is actually attached to a PageView
        if (!_featuredPageController.hasClients) return;

        final now = DateTime.now();
        final upcomingCount = _events!
            .where((e) => e.date.isAfter(now) || e.date.isAtSameMomentAs(now))
            .take(5)
            .length;
        if (upcomingCount > 1) {
          int nextPage = (_currentFeaturedIndex + 1) % upcomingCount;
          _featuredPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadEvents() async {
    try {
      final events = await EventService.getAllEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Debounced reload — prevents rapid-fire reloads from real-time subscriptions
  void _debouncedReload() {
    // Skip reload if any reaction is still being processed
    if (_processingReactions.isNotEmpty) return;

    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _loadEvents();
    });
  }

  void _setupRealTimeSubscription() {
    _eventsSubscription = SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (mounted) _debouncedReload();
        });

    _reactionsSubscription = SupabaseService.client
        .from('event_reactions')
        .stream(primaryKey: ['id'])
        .listen((_) {
          if (mounted) _debouncedReload();
        });
  }

  void _loadReactions() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _userId = user.id;
      _loadUserReactions();
    }
  }

  Future<void> _loadUserReactions() async {
    if (_userId == null) return;
    final reactions = await ReactionService.getUserReactions(_userId!);
    if (mounted) {
      setState(() => _userReactions = reactions);
    }
  }

  Future<void> _loadBookmarks() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final bookmarks = await BookmarkService.getBookmarks(user.id);
      if (mounted) {
        setState(() => _bookmarkedEventIds = bookmarks.toSet());
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark(String eventId) async {
    if (_userId == null) return;
    // Optimistic UI update
    setState(() {
      if (_bookmarkedEventIds.contains(eventId)) {
        _bookmarkedEventIds.remove(eventId);
      } else {
        _bookmarkedEventIds.add(eventId);
      }
    });
    try {
      await BookmarkService.toggleBookmark(_userId!, eventId);
    } catch (_) {
      // Revert on error
      setState(() {
        if (_bookmarkedEventIds.contains(eventId)) {
          _bookmarkedEventIds.remove(eventId);
        } else {
          _bookmarkedEventIds.add(eventId);
        }
      });
    }
  }

  Future<void> _toggleReaction(String eventId, ReactionType type) async {
    if (_userId == null) return;

    // Cancel any pending debounce for this event
    _reactionDebounceTimers[eventId]?.cancel();

    final previousReaction = _userReactions[eventId];

    // 1. Optimistic UI update — reaction icon state
    setState(() {
      if (previousReaction == type) {
        _userReactions.remove(eventId);
      } else {
        _userReactions[eventId] = type;
      }
    });

    // 2. Optimistic count update on the local event object
    if (_events != null) {
      final idx = _events!.indexWhere((e) => e.id == eventId);
      if (idx != -1) {
        final event = _events![idx];
        int newLikes = event.likeCount;
        int newDislikes = event.dislikeCount;

        if (previousReaction == ReactionType.like) newLikes = (newLikes - 1).clamp(0, 99999);
        if (previousReaction == ReactionType.dislike) newDislikes = (newDislikes - 1).clamp(0, 99999);

        if (previousReaction != type) {
          if (type == ReactionType.like) newLikes++;
          if (type == ReactionType.dislike) newDislikes++;
        }

        setState(() {
          _events![idx] = event.copyWith(likeCount: newLikes, dislikeCount: newDislikes);
        });
      }
    }

    // 3. Debounced DB call — only fires after user stops tapping for 600ms
    _reactionDebounceTimers[eventId] = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      _processingReactions.add(eventId);

      try {
        // Determine final desired state from current optimistic UI
        final desiredReaction = _userReactions[eventId];

        // Get actual DB state to decide what operation to perform
        final currentDbReaction = await ReactionService.getUserReaction(_userId!, eventId);

        if (desiredReaction == currentDbReaction) {
          // Already in sync — nothing to do
        } else if (desiredReaction == null && currentDbReaction != null) {
          // User toggled off — remove
          await ReactionService.toggleReaction(_userId!, eventId, currentDbReaction);
        } else if (desiredReaction != null && currentDbReaction == null) {
          // User added reaction — insert
          await ReactionService.toggleReaction(_userId!, eventId, desiredReaction);
        } else if (desiredReaction != null && currentDbReaction != null && desiredReaction != currentDbReaction) {
          // User switched reaction — toggle current off then add new
          await ReactionService.toggleReaction(_userId!, eventId, currentDbReaction);
          await ReactionService.toggleReaction(_userId!, eventId, desiredReaction);
        }

        // Reload events to get authoritative counts from DB trigger
        if (mounted) await _loadEvents();
      } catch (e) {
        // On error, reload everything to resync
        if (mounted) {
          _loadUserReactions();
          _loadEvents();
        }
      } finally {
        _processingReactions.remove(eventId);
      }
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day} • ${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')} PM';
  }

  String _formatLikeCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  // Only admins can create events from the general Events page
  // Presidents should create events from their Society page
  bool _canAddEvents() {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.admin ||
           user.role == UserRole.superAdmin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: _canAddEvents()
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/add-event');
                  if (result == true) {
                    _loadEvents();
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Animated particle background
          _buildParticleBackground(),

          // Background glow effects
          _buildBackgroundGlows(),

          // Main content
          SafeArea(
            top: false, // AppBar handles top safe area
            child: _isLoading
              ? _buildLoadingState()
              : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGlows() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.8 + _pulseController.value * 0.4;
        return Stack(
          children: [
            // Top-right purple glow
            Positioned(
              top: -80,
              right: -80,
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9D4EDD).withOpacity(0.25),
                        const Color(0xFF9D4EDD).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left magenta glow
            Positioned(
              bottom: -100,
              left: -60,
              child: Transform.scale(
                scale: 1.2 - (_pulseController.value * 0.2),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE040FB).withOpacity(0.2),
                        const Color(0xFFE040FB).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF9D4EDD),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading events...',
            style: TextStyle(
              color: Color(0xFFB8A9C9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final now = DateTime.now();
    final allEvents = _events ?? [];

    // Split into upcoming (active) and past events
    final upcomingEvents = allEvents
        .where((e) => e.date.isAfter(now) || e.date.isAtSameMomentAs(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // earliest first

    final pastEvents = allEvents
        .where((e) => e.date.isBefore(now))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // latest first

    // ── Smart Featured Logic ──
    // 1. Manually featured events first (admin-marked)
    final manuallyFeatured = upcomingEvents.where((e) => e.isFeatured).toList();
    // 2. Fill remaining slots (up to 5 total) with highest-attendee upcoming events
    final autoFeatured = upcomingEvents
        .where((e) => !e.isFeatured)
        .toList()
      ..sort((a, b) => b.currentAttendees.compareTo(a.currentAttendees));
    final featuredEvents = [
      ...manuallyFeatured,
      ...autoFeatured.take((5 - manuallyFeatured.length).clamp(0, 5)),
    ];

    // Last 10 past events
    final recentPastEvents = pastEvents.take(10).toList();

    return FadeTransition(
      opacity: _fadeController,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Search bar
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),

          // Featured Events Section (upcoming only)
          SliverToBoxAdapter(
            child: _buildSectionHeader('Featured Event', 'See All', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Showing all events below'),
                  backgroundColor: Color(0xFF9D4EDD),
                ),
              );
            }),
          ),

          // Featured Carousel - Swipeable (upcoming only)
          SliverToBoxAdapter(
            child: _buildFeaturedCarousel(featuredEvents),
          ),

          // For You Section (upcoming only)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _buildSectionHeader('For You', 'See All', () {
                Navigator.pushNamed(context, '/search');
              }),
            ),
          ),

          // Upcoming Events List
          if (upcomingEvents.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= upcomingEvents.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEventListCard(upcomingEvents[index]),
                    );
                  },
                  childCount: upcomingEvents.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Color(0xFFB8A9C9)),
                      SizedBox(height: 12),
                      Text(
                        'No upcoming events',
                        style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Check back later for new events!',
                        style: TextStyle(color: Color(0xFF7A6B8F), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Past Events Section ──
          if (recentPastEvents.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: _buildSectionHeader('Past Events', '${recentPastEvents.length} recent', () {}),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= recentPastEvents.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPastEventCard(recentPastEvents[index]),
                    );
                  },
                  childCount: recentPastEvents.length,
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  /// Builds a card for past events with a dimmed style and "ENDED" badge
  Widget _buildPastEventCard(Event event) {

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: event.id),
      child: Opacity(
        opacity: 0.75,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF3D3557).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Event Image with "ENDED" overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      event.imageUrl != null && event.imageUrl!.isNotEmpty
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
                            )
                          : _buildSmallPlaceholder(),
                      // Dark overlay
                      Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                      // "ENDED" badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Event Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date
                    Text(
                      _formatDate(event.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A6B8F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF7A6B8F),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A6B8F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Reaction counts + attendees for past events
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_rounded, size: 12, color: Color(0xFF7A6B8F)),
                        const SizedBox(width: 3),
                        Text('${event.likeCount}', style: const TextStyle(fontSize: 11, color: Color(0xFF7A6B8F))),
                        const SizedBox(width: 10),
                        const Icon(Icons.thumb_down_rounded, size: 12, color: Color(0xFF7A6B8F)),
                        const SizedBox(width: 3),
                        Text('${event.dislikeCount}', style: const TextStyle(fontSize: 11, color: Color(0xFF7A6B8F))),
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline, size: 12, color: Color(0xFF7A6B8F)),
                        const SizedBox(width: 3),
                        Text(
                          '${event.currentAttendees} attended',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7A6B8F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable pill-style reaction button for featured cards
  Widget _buildReactionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2645),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: activeColor.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 16,
              color: isActive ? activeColor : const Color(0xFFB8A9C9),
            ),
            const SizedBox(width: 6),
            Text(
              _formatLikeCount(count),
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : const Color(0xFFB8A9C9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/search'),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFF3D3557).withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9D4EDD).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: Color(0xFFB8A9C9),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'I am looking for...',
                  style: TextStyle(
                    color: Color(0xFFB8A9C9),
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2645),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFFB8A9C9),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9D4EDD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<Event> events) {
    if (events.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3D3557)),
        ),
        child: const Center(
          child: Text(
            'No featured events',
            style: TextStyle(color: Color(0xFFB8A9C9)),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _featuredPageController,
            // Use PageScrollPhysics for better web/desktop swipe support
            physics: const PageScrollPhysics(),
            padEnds: true,
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() => _currentFeaturedIndex = index);
              // Reset auto-scroll timer when user manually swipes
              _autoScrollTimer?.cancel();
              _startAutoScroll();
            },
            itemCount: events.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _featuredPageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_featuredPageController.position.haveDimensions) {
                    value = (_featuredPageController.page! - index).abs();
                    value = (1 - (value * 0.12)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: Opacity(
                      opacity: value.clamp(0.7, 1.0),
                      child: _buildFeaturedCard(events[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Pagination dots with animation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(events.length, (index) {
            final isActive = index == _currentFeaturedIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: isActive ? const LinearGradient(
                  colors: [Color(0xFF9D4EDD), Color(0xFFE040FB)],
                ) : null,
                color: isActive ? null : const Color(0xFF3D3557),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ] : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Event event) {
    final userReaction = _userReactions[event.id];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: event.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF3D3557).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D4EDD).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image with overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 210,
                          errorWidget: (_, __, ___) => _buildPlaceholderImage(),
                          placeholder: (_, __) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Event Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date
                    Text(
                      _formatDate(event.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB8A9C9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF9D4EDD),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB8A9C9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Actions row: Like, Dislike, Attendees
                    Row(
                      children: [
                        // Like button
                        _buildReactionButton(
                          icon: Icons.thumb_up_rounded,
                          activeIcon: Icons.thumb_up_rounded,
                          count: event.likeCount,
                          isActive: userReaction == ReactionType.like,
                          activeColor: const Color(0xFF22C55E),
                          onTap: () => _toggleReaction(event.id, ReactionType.like),
                        ),
                        const SizedBox(width: 8),
                        // Dislike button
                        _buildReactionButton(
                          icon: Icons.thumb_down_outlined,
                          activeIcon: Icons.thumb_down_rounded,
                          count: event.dislikeCount,
                          isActive: userReaction == ReactionType.dislike,
                          activeColor: const Color(0xFFEF4444),
                          onTap: () => _toggleReaction(event.id, ReactionType.dislike),
                        ),
                        const Spacer(),
                        // Attendee count (registration-based)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2645),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, size: 14, color: Color(0xFF9D4EDD)),
                              const SizedBox(width: 4),
                              Text(
                                '${event.currentAttendees}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFB8A9C9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bookmark button
                        GestureDetector(
                          onTap: () => _toggleBookmark(event.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2645),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _bookmarkedEventIds.contains(event.id)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 18,
                              color: _bookmarkedEventIds.contains(event.id)
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFB8A9C9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildEventListCard(Event event) {
    final userReaction = _userReactions[event.id];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: event.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF3D3557).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Event Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 100,
                height: 100,
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                  ? Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
                    )
                  : _buildSmallPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Date - Purple color like design
                  Text(
                    _formatDate(event.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9D4EDD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFFB8A9C9),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB8A9C9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Like / Dislike / Attendees row
                  Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: () => _toggleReaction(event.id, ReactionType.like),
                        child: Row(
                          children: [
                            Icon(
                              userReaction == ReactionType.like
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_outlined,
                              size: 14,
                              color: userReaction == ReactionType.like
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFB8A9C9),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${event.likeCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: userReaction == ReactionType.like
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFB8A9C9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dislike
                      GestureDetector(
                        onTap: () => _toggleReaction(event.id, ReactionType.dislike),
                        child: Row(
                          children: [
                            Icon(
                              userReaction == ReactionType.dislike
                                  ? Icons.thumb_down_rounded
                                  : Icons.thumb_down_outlined,
                              size: 14,
                              color: userReaction == ReactionType.dislike
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFB8A9C9),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${event.dislikeCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: userReaction == ReactionType.dislike
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFB8A9C9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Attendees (separate from reactions)
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Color(0xFF9D4EDD)),
                          const SizedBox(width: 3),
                          Text(
                            '${event.currentAttendees}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFB8A9C9)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bookmark button
                      GestureDetector(
                        onTap: () => _toggleBookmark(event.id),
                        child: Icon(
                          _bookmarkedEventIds.contains(event.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: _bookmarkedEventIds.contains(event.id)
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFB8A9C9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          color: Colors.white.withOpacity(0.5),
          size: 36,
        ),
      ),
    );
  }
}

// Simple particle model
class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Particle painter for background effects
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = (animationValue + particle.y) % 1.0;
      final x = particle.x * size.width +
                math.sin(progress * 2 * math.pi) * 20 * particle.speed;
      final y = (1 - progress) * size.height;

      final opacity = (particle.opacity * (1 - progress * 0.5)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF9D4EDD),
          const Color(0xFFE040FB),
          particle.x,
        )!.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // Glow effect
      final glowPaint = Paint()
        ..color = const Color(0xFF9D4EDD).withOpacity((opacity * 0.3).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(x, y), particle.size * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
