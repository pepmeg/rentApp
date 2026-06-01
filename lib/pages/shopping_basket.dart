import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lease_request.dart';
import '../widgets/basket_card.dart';
import '../provider/basket_provider.dart';
import '../provider/AuthProvider.dart';
import '../utils/snackbar_custom.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

class BasketState extends State<ShoppingBasket> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<AuthProvider>().isUser) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<BasketProvider>().loadForUser(user.uid);
      }
    });
  }

  Future<void> _pay(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final basket = context.read<BasketProvider>();
    final cartItems = basket.getItemsForUser(user.uid);
    if (cartItems.isEmpty) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.incrementRating(user.uid);
    await authProvider.resetUnpaidLeaseCount(user.uid);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final item in cartItems) {
      final querySnapshot = await firestore
          .collection('lease_requests')
          .where('productId', isEqualTo: item.id)
          .where('requesterId', isEqualTo: user.uid)
          .where('status', isEqualTo: RequestStatus.accepted.index)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        final archiveData = Map<String, dynamic>.from(data);
        archiveData['archivedAt'] = FieldValue.serverTimestamp();

        final archiveRef = firestore.collection('lease_requests_archive').doc();
        batch.set(archiveRef, archiveData);
        batch.delete(doc.reference);
      }
    }

    final cartSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();
    for (final doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    basket.clearCartForUser(user.uid);
    SnackBarCustom.show(context, message: 'Оплата прошла успешно!');
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isUser) {
      return const SizedBox.shrink();
    }

    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final basketProvider = context.watch<BasketProvider>();
    final cartItems = basketProvider.getItemsForUser(user.uid);
    final totalPrice = basketProvider.totalPriceForUser(user.uid);
    final isBlocked = user?.blocked == true;
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Корзина',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${cartItems.length} товара',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ваша корзина пуста',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Завершённые аренды появятся здесь',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return BasketCard(item: item);
                },
              ),
            ),
            if (cartItems.isNotEmpty) ...[
              const Divider(height: 2, thickness: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Итого',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalPrice ₽',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: cartItems.isNotEmpty && !isBlocked ? () => _pay(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.3),
                foregroundColor: theme.colorScheme.onPrimary,
                disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                'Оплатить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}