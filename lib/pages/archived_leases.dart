import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/archived_leases_provider.dart';
import '../widgets/CompletedLeaseCard.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';

class ArchivedLeasesScreen extends StatefulWidget {
  const ArchivedLeasesScreen({super.key});

  @override
  State<ArchivedLeasesScreen> createState() => _ArchivedLeasesScreenState();
}

class _ArchivedLeasesScreenState extends State<ArchivedLeasesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context
          .read<AuthProvider>()
          .currentUser
          ?.uid;
      if (userId != null) {
        context
            .read<ArchivedLeasesProvider>()
            .loadArchivedForUser(userId)
            .then((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final archivedProvider = context.watch<ArchivedLeasesProvider>();
    final leases = archivedProvider.completedLeases;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'История аренд'),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : leases.isEmpty
                  ? const EmptyState(
                icon: Icons.history,
                title: 'Нет завершённых аренд',
              )
                  : ListView.builder(
                itemCount: leases.length,
                itemBuilder: (context, index) {
                  final lease = leases[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CompletedLeaseCard(lease: lease),
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