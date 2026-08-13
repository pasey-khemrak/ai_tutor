import 'package:flutter/material.dart';

import '../core/adaptive_colors.dart';
import '../core/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItem(Icons.dashboard_outlined, 'Home'),
    _NavItem(Icons.smart_toy_outlined, 'Tutor'),
    _NavItem(Icons.mic_none_rounded, 'Voice'),
    _NavItem(Icons.quiz_outlined, 'Lessons'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final backgroundColor = isLight
        ? Colors.white.withValues(alpha: .94)
        : AppColors.panel.withValues(alpha: .86);
    final borderColor = isLight
        ? const Color(0xFFD8DEEC)
        : Colors.white.withValues(alpha: .06);

    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: const Color(0xFF172033).withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: _NavButton(
                item: _items[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final color = selected
        ? (isLight ? AppColors.blue : AppColors.cyan)
        : (isLight ? const Color(0xFF69738A) : AppColors.muted);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
