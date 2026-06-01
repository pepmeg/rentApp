import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activeLease.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../widgets/lease_card/lease_card.dart';

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
                  'Активные аренды (мои товары)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}