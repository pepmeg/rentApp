import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/LeaseRequestProvider.dart';
import '../services/connectivityService.dart';
import '../widgets/lease_request_card.dart';
import '../provider/bottom_nav_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final requests = context.watch<LeaseRequestProvider>().getIncomingRequests(user.uid);
    final connectivity = context.watch<ConnectivityService>();
    final hasInternet = connectivity.hasInternet;
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                Text(
                  'Запросы',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const Spacer(),
                if (!hasInternet)
                  IconButton(
                    icon: Icon(Icons.sync, color: theme.primaryColor),
                    onPressed: () {
                      context.read<LeaseRequestProvider>().loadRequests();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasInternet)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 18, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Нет подключения к интернету. Данные могут быть неактуальны.',
                        style: TextStyle(fontSize: 13, color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                child: Text(
                  hasInternet ? 'Нет входящих запросов' : 'Нет запросов (офлайн)',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              )
                  : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return LeaseRequestCard(
                    request: request,
                    onUserTap: () {
                      context.read<BottomNavProvider>().showUserProfile(request.requesterId);
                      Navigator.popUntil(context, (route) => route.isFirst);
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