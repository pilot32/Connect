import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/core/state/refresh_with_error_report.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_animated_size.dart';
import 'package:connectappfe/core/widgets/async_view.dart';
import 'package:connectappfe/core/widgets/brand_mark.dart';
import 'package:connectappfe/core/widgets/fade_slide_in.dart';
import 'package:connectappfe/core/widgets/skeleton.dart';
import 'package:connectappfe/core/widgets/user_avatar.dart';
import 'package:connectappfe/features/feed/models/post.dart';
import 'package:connectappfe/features/feed/state/feed_controller.dart';
import 'package:connectappfe/features/feed/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Chronological feed of posts from the user's connections, plus their own.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Skips the entrance animation for posts already shown once, so scrolling
  /// past ~10 posts and back doesn't re-blank each recycled row.
  final PlayedOnceTracker _played = PlayedOnceTracker();

  /// The composer FAB retracts to a circle while scrolling down and expands
  /// again on scroll up, so it stops covering a post mid-read.
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FeedController>().loadOnce();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final direction = _scrollController.position.userScrollDirection;
    final shouldExtend = direction != ScrollDirection.reverse;
    if (shouldExtend != _fabExtended) {
      setState(() => _fabExtended = shouldExtend);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        title: const Row(
          children: <Widget>[
            BrandMark(size: 28, heroTag: null),
            SizedBox(width: AppSpacing.xs),
            BrandWordmark(fontSize: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.composePost),
        icon: const Icon(Icons.edit_outlined),
        label: AppAnimatedSize(
          alignment: Alignment.centerLeft,
          child: _fabExtended
              ? const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text('Post'),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshWithErrorReport(context, feed),
        child: AsyncView<List<Post>>(
          controller: feed,
          isEmpty: (data) => data.isEmpty,
          loadingPlaceholder: SkeletonList(
            count: 3,
            itemBuilder: (context) => const PostSkeleton(),
          ),
          emptyIcon: Icons.dynamic_feed_outlined,
          emptyTitle: 'Your feed is quiet',
          emptyMessage:
              'Posts from officials you connect with appear here. Write the '
              'first one, or find peers in Search.',
          emptyActionLabel: 'Write a post',
          onEmptyAction: () => context.push(AppRoutes.composePost),
          builder: (context, posts) {
            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                // Clears the FAB.
                AppSpacing.huge + AppSpacing.lg,
              ),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final post = posts[index];
                final alreadyShown = _played.consume(post.id);
                return FadeSlideIn(
                  // Keyed by post id so a newly created post animates in on its
                  // own rather than the whole list replaying.
                  key: ValueKey<String>('post-${post.id}'),
                  delay: alreadyShown ? Duration.zero : context.stagger(index),
                  duration: alreadyShown ? Duration.zero : AppMotion.slow,
                  scaleFrom: 0.97,
                  child: PostCard(
                    post: post,
                    heroTag: AvatarHeroTag.feedPost(post.id),
                    onAuthorTap: () => context.push(
                      AppRoutes.userProfile(post.author.id),
                      extra: AvatarHeroTag.feedPost(post.id),
                    ),
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
