import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/LeaseRequestProvider.dart';
import '../utils/colors.dart';
import '../widgets/lease_request_card.dart';
import '../provider/bottom_nav_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final requests = context.watch<LeaseRequestProvider>()
        .getIncomingRequests(user.id);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                const Text('Запросы',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                  child: Text('Нет входящих запросов',
                      style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5))))
                  : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return LeaseRequestCard(
                    request: request,
                    onUserTap: () {
                      final isUser = context.read<AuthProvider>().isUser;
                      context.read<BottomNavProvider>().showUserProfile(
                        request.requesterId,
                        isUser: isUser,
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}