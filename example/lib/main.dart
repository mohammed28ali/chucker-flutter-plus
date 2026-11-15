import 'package:chucker_flutter_plus/chucker_flutter_plus.dart';
import 'package:flutter/material.dart';

import 'core/di/dependency_injection.dart';
import 'domain/repositories/posts_repository.dart';
import 'domain/usecases/create_demo_post.dart';
import 'domain/usecases/get_missing_post.dart';
import 'domain/usecases/get_post.dart';
import 'domain/usecases/get_posts.dart';
import 'presentation/dashboard_view_model.dart';
import 'presentation/models/dashboard_state.dart';
import 'presentation/models/post.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChuckerFlutterPlus.initialize(
    maximumEntries: 200,
    retention: const Duration(days: 7),
    redactHeaders: {'authorization', 'cookie', 'set-cookie', 'x-api-key'},
  );
  runApp(
    ChuckerExampleApp(repository: DependencyInjection.createPostsRepository()),
  );
}

class ChuckerExampleApp extends StatelessWidget {
  const ChuckerExampleApp({super.key, required this.repository});

  final PostsRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chucker Plus',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6658E8),
        brightness: Brightness.light,
        surface: const Color(0xFFF8F8FC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8FC),
      fontFamily: 'Roboto',
    ),
    home: DashboardPage(
      viewModel: DashboardViewModel(
        getPosts: GetPosts(repository),
        getPost: GetPost(repository),
        getMissingPost: GetMissingPost(repository),
        createDemoPost: CreateDemoPost(repository),
      ),
    ),
  );
}

final class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardViewModel get _viewModel => widget.viewModel;
  DashboardState get _state => _viewModel.state;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showPost(Post post) async {
    final result = await _viewModel.fetchPost(post.id);
    if (!mounted || result == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POST #${result.id}',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              result.body,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    void openInspector() => ChuckerFlutterPlus.showInspector(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chucker Plus',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'NETWORK PLAYGROUND',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    color: Color(0xFF77758A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Open network inspector',
            onPressed: openInspector,
            icon: const Icon(Icons.network_check_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _HeroCard(onOpen: openInspector),
            const SizedBox(height: 25),
            const _SectionHeading(
              eyebrow: 'MAKE A REQUEST',
              title: 'Try the inspector',
            ),
            const SizedBox(height: 13),
            _RequestTile(
              icon: Icons.view_list_rounded,
              tint: const Color(0xFF6658E8),
              title: 'Fetch recent posts',
              subtitle: 'GET  /posts?_limit=8',
              onTap: _viewModel.fetchPosts,
            ),
            _RequestTile(
              icon: Icons.add_rounded,
              tint: const Color(0xFF208A70),
              title: 'Create a post',
              subtitle: 'POST  /posts',
              onTap: _viewModel.createPost,
            ),
            _RequestTile(
              icon: Icons.warning_amber_rounded,
              tint: const Color(0xFFD88724),
              title: 'Trigger a not-found response',
              subtitle: 'GET  /posts/0  ·  expected 404',
              onTap: _viewModel.fetchMissingPost,
            ),
            if (_state.message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_state.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _state.message!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_state.posts.isNotEmpty) ...[
              const SizedBox(height: 25),
              _SectionHeading(
                eyebrow: 'LIVE RESPONSE',
                title: 'Posts',
                trailing: '${_state.posts.length} items',
              ),
              const SizedBox(height: 12),
              ..._state.posts
                  .take(5)
                  .map(
                    (post) => _PostCard(
                      title: post.title,
                      body: post.body,
                      onTap: () => _showPost(post),
                    ),
                  ),
            ],
            const SizedBox(height: 23),
            _TipCard(onOpen: openInspector),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openInspector,
        icon: const Icon(Icons.query_stats_rounded),
        label: const Text('Inspect traffic'),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF25213E), Color(0xFF5142A2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(23),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5142A2).withValues(alpha: .2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF72E0B3)),
                  SizedBox(width: 7),
                  Text(
                    'CAPTURE ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.radar_rounded, color: Color(0xFFBDB6FF), size: 27),
          ],
        ),
        const SizedBox(height: 23),
        const Text(
          'Every request,\nin clear view.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Make a call below, then explore headers, payloads and timing in your local inspector.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .75),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onOpen,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: .15),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Open inspector'),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
          ],
        ),
      ),
      if (trailing != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            trailing!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ],
  );
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 9),
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: Color(0xFFECEBF2)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF77758A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9B99A8)),
          ],
        ),
      ),
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.title,
    required this.body,
    required this.onTap,
  });
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: Color(0xFFECEBF2)),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
    ),
    trailing: const Icon(Icons.arrow_outward_rounded, size: 16),
    onTap: onTap,
  );
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDEBFF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF5142A2)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pro tip',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Tap any request in the inspector to review its full timeline and response body.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpen,
          tooltip: 'Open inspector',
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        ),
      ],
    ),
  );
}
