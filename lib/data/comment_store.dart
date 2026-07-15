import 'package:flutter/foundation.dart';

/// A single comment on a post. Mentions are written inline as "@Name" tokens.
class Comment {
  Comment({required this.author, required this.text, this.time = 'Just now'});
  final String author;
  final String text;
  final String time;
}

/// App-wide, in-memory store of comments keyed by post id. Seeded with demo
/// conversation so "View all comments" shows others' comments too. Comments the
/// user adds are appended live (newest last, Instagram-style).
class CommentStore extends ChangeNotifier {
  CommentStore._() {
    _seed();
  }
  static final CommentStore instance = CommentStore._();

  final Map<String, List<Comment>> _byPost = {};

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_byPost[postId] ?? const <Comment>[]);

  int countFor(String postId) => _byPost[postId]?.length ?? 0;

  void add(String postId, Comment c) {
    (_byPost[postId] ??= <Comment>[]).add(c);
    notifyListeners();
  }

  void _seed() {
    _byPost['seed-0'] = [
      Comment(
          author: 'Gopalakrishna Suvarna',
          text: 'What a treasure! 🙏 Those were golden days.',
          time: '2h'),
      Comment(
          author: 'Savita Haldankar',
          text: '@VenkateshHaldankar thank you for preserving this 🙏',
          time: '1h'),
      Comment(
          author: 'Deepak Vernekar',
          text: 'Is that my grandfather in the back row? 😍',
          time: '45m'),
    ];
    _byPost['seed-1'] = [
      Comment(
          author: 'Rohit Suvarna',
          text: 'Thank you @ShriNarayanaraoSuvarna 🙏 means a lot',
          time: '20h'),
      Comment(
          author: 'Nandini Kolwekar',
          text: 'So happy to see our lineage documented!',
          time: '18h'),
    ];
    _byPost['seed-2'] = [
      Comment(
          author: 'Lakshmi Revankar',
          text: 'Happy birthday Rekha! 🎂🎉',
          time: '5h'),
      Comment(
          author: 'Vivek Kolwekar', text: 'Many happy returns! 🎉', time: '4h'),
      Comment(
          author: 'Pooja Karekar',
          text: 'Wishing you joy always ❤️',
          time: '2h'),
    ];
    _byPost['seed-3'] = [
      Comment(
          author: 'Ravi Kumar Potdar',
          text: 'Donated! Proud to support our Samaj 🙏',
          time: '1d'),
      Comment(
          author: 'Girish Raikar',
          text: 'The new auditorium will be wonderful for our functions.',
          time: '1d'),
    ];
    _byPost['seed-4'] = [
      Comment(
          author: 'Tejaswini Balgi',
          text: 'Beautiful rendition 🎶 @KarthikRevankar',
          time: '3d'),
      Comment(author: 'Usha Gaunkar', text: 'Goosebumps! 👏', time: '3d'),
    ];
  }
}
