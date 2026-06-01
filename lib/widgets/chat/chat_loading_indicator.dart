import 'package:flutter/material.dart';

class ChatLoadingIndicator extends StatelessWidget {
  const ChatLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}