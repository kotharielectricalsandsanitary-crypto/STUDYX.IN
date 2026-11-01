class AICommandResponse {
  final String message;
  final List<Map<String, dynamic>> actions;

  const AICommandResponse({
    required this.message,
    required this.actions,
  });

  factory AICommandResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawActions = json['actions'];

    final actions = <Map<String, dynamic>>[];

    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is Map) {
          actions.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    return AICommandResponse(
      message: json['message']?.toString() ?? '',
      actions: actions,
    );
  }
}