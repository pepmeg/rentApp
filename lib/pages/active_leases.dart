import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/lease_card.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';

import '../provider/AuthProvider.dart';

class ActiveLeases extends StatelessWidget {
  const ActiveLeases({super.key});

  @override
  Widget build(BuildContext context) {

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final leases = context.watch<ActiveLeasesProvider>().getLeasesForUser(user.id);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Активные аренды',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: leases.length,
                itemBuilder: (context, index) {
                  final lease = leases[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LeaseCard(lease: lease),
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