enum FeedbackType { bug, idea }

class FeedbackItem {
  const FeedbackItem({required this.type, required this.message});

  final FeedbackType type;
  final String message;
}
