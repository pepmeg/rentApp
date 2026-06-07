import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activeLease.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../widgets/lease_card/lease_card.dart';
import '../widgets/screen_header.dart';

class ActiveLeasesAsOwner extends StatelessWidget {
  const ActiveLeasesAsOwner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final ownerLeases = leasesProvider.leases.where((lease) =>
    lease.ownerId == user.uid &&
        (lease.status == LeaseStatus.active || lease.status == LeaseStatus.pendingCompletion)
    ).toList();
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'Активные аренды (мои товары)'),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ownerLeases.isEmpty
                  ? Center(
                child: Text(
                  'Нет активных аренд ваших товаров',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              )
                  : ListView.builder(
                itemCount: ownerLeases.length,
                itemBuilder: (context, index) {
                  final lease = ownerLeases[index];
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