import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';
import 'package:untitled/utils/colors.dart';
import '../provider/LeaseRequestProvider.dart';
import '../widgets/product_image.dart';

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
                  icon: const Icon(Icons.arrow_back,
                      size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                const Text('Запросы на аренду',
                    style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oliveGray)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                  child: Text('Нет входящих запросов',
                      style: TextStyle(
                          color: AppColors.oliveGray.withOpacity(0.5))))
                  : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    color: AppColors.whiteAntique,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductImage(
                            images: req.images,
                            width: 70,
                            height: 70,
                            backgroundColor: AppColors.whiteAntique,
                          ),
                          const SizedBox(width: 15),
                          // Текст и кнопки
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.productName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.oliveGray,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text('${req.pricePerDay} ₽/день',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.oliveGray,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<LeaseRequestProvider>()
                                            .acceptRequest(
                                            req.id,
                                            context.read<ActiveLeasesProvider>());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.lightGreen,
                                        foregroundColor: AppColors.oliveGray,
                                      ),
                                      child: const Text('Принять'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<LeaseRequestProvider>()
                                            .rejectRequest(req.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.copper,
                                        foregroundColor: AppColors.whiteAntique,
                                      ),
                                      child: const Text('Отклонить'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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