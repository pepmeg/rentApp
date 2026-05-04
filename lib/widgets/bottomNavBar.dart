import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/chat_provider.dart';
import '../utils/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isUser;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final userId = auth.currentUser?.id;
    final unreadChats = userId != null ? chatProvider.unreadChatsCount(userId) : 0;

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
      if (isUser)
        const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Избранное'),
      if (isUser)
        const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Добавить'),
      if (isUser)
        const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Корзина'),
      BottomNavigationBarItem(
        icon: _buildChatIcon(unreadChats),
        label: 'Чат',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
    ];

    final safeIndex = currentIndex.clamp(0, items.length - 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) {
          if (index < items.length) {
            onTap(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.spaceCream,
        selectedItemColor: AppColors.copper,
        unselectedItemColor: AppColors.oliveGray.withOpacity(0.5),
        iconSize: 28,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
        items: items,
      ),
    );
  }

  Widget _buildChatIcon(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.copper,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}