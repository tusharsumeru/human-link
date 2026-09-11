import 'dart:async';

/// A successful follow/unfollow between two members.
typedef FollowChange = ({
  String followerId,
  String followingId,
  bool following,
});

/// Broadcasts follow/unfollow relationship changes app-wide, so any
/// currently-visible follower/following stat (e.g. on a profile screen
/// reached via an earlier route) can update in place instead of showing a
/// stale count fetched once at `initState`.
class FollowEvents {
  FollowEvents._();

  static final _controller = StreamController<FollowChange>.broadcast();

  static Stream<FollowChange> get stream => _controller.stream;

  static void emit({
    required String followerId,
    required String followingId,
    required bool following,
  }) {
    _controller.add((
      followerId: followerId,
      followingId: followingId,
      following: following,
    ));
  }
}
