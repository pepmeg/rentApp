import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../widgets/empty_state.dart';
import '../widgets/lease_card/lease_card.dart';
import '../widgets/screen_header.dart';

class ActiveLeases extends StatelessWidget {
  const ActiveLeases({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final leases = context.watch<ActiveLeasesProvider>().getLeasesForUser(user.uid);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'Активные аренды'),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: leases.isEmpty
                  ? const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Нет активных аренд',
                subtitle: 'Когда вы арендуете товар, он появится здесь',
              )
                  : ListView.builder(
                itemCount: leases.length,
                itemBuilder: (context, index) {
                  final lease = leases[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LeaseCard(
                      key: ValueKey('lease-${lease.productId}-${lease.status}'),
                      lease: lease,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}