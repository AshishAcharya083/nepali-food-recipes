import 'package:flutter/material.dart';
import 'package:nepali_food_recipes/constants.dart';

class DrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;

  DrawerTile(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: kSecondaryColor,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}
