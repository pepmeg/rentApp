import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/archived_leases_provider.dart';
import '../widgets/CompletedLeaseCard.dart';

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
      final userId = context.read<AuthProvider>().currentUser?.uid;
      if (userId != null) {
        context.read<ArchivedLeasesProvider>().loadArchivedForUser(userId).then((_) {
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
                  'История аренд',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : leases.isEmpty
                  ? Center(
                child: Text(
                  'Нет завершённых аренд',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
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
          ],
        ),
      ),
    );
  }
}