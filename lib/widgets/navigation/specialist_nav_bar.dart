import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:armstrong/config/colors.dart';

class SpecialistBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final int notificationCount;
  final int chatNotificationCount;

  const SpecialistBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.notificationCount = 0,
    this.chatNotificationCount = 0,
  }) : super(key: key);

  Widget _buildBadge(int count) {
    return count > 0
        ? Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    )
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      items: <Widget>[
        Icon(Icons.home_filled, size: 30, color: Colors.white),

        Stack(
          children: [
            Icon(Icons.message_outlined, size: 30, color: Colors.white),
            _buildBadge(chatNotificationCount),
          ],
        ),

        Stack(
          children: [
            Icon(Icons.edit_calendar, size: 30, color: Colors.white),
            _buildBadge(notificationCount), 
          ],
        ),
      ],
      index: selectedIndex,
      color: buttonColor,
      buttonBackgroundColor: orangeContainer,
      backgroundColor: Colors.white,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      onTap: (index) {
        onItemTapped(index);
      },
      letIndexChange: (index) => true,
    );
  }
}
