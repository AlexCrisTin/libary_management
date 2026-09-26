import 'package:flutter/material.dart';

class ApiStateView extends StatelessWidget {
  const ApiStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = 'Chưa có dữ liệu',
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (isEmpty) return Center(child: Text(emptyMessage));
    return child;
  }
}
