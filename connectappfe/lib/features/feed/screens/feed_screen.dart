import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../models/post.dart';
import '../state/feed_controller.dart';
import '../widgets/post_card.dart';

/// Chronological feed of posts from the user's connections, plus their own.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FeedController>().loadOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final FeedController feed = context.watch<FeedController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        title: Row(
          children: const <Widget>[
            BrandMark(size: 28, heroTag: null),
            SizedBox(width: AppSpacing.xs),
            BrandWordmark(fontSize: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.composePost),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
      ),
      body: RefreshIndicator(
        onRefresh: () => feed.load(silent: true),
        child: AsyncView<List<Post>>(
          controller: feed,
          isEmpty: (List<Post> data) => data.isEmpty,
          emptyIcon: Icons.dynamic_feed_outlined,
          emptyTitle: 'Your feed is quiet',
          emptyMessage:
              'Posts from officials you connect with appear here. Write the '
              'first one, or find peers in the directory.',
          emptyActionLabel: 'Write a post',
          onEmptyAction: () => context.push(AppRoutes.composePost),
          builder: (BuildContext context, List<Post> posts) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                // Clears the FAB.
                AppSpacing.huge + AppSpacing.lg,
              ),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final Post post = posts[index];
                return FadeSlideIn(
                  delay: AppMotion.stagger * (index.clamp(0, 6)),
                  child: PostCard(
                    post: post,
                    onAuthorTap: () =>
                        context.push(AppRoutes.userProfile(post.author.id)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
