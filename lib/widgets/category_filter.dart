import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.categories.length,
        itemBuilder: (context, i) {
          final cat = AppConstants.categories[i];
          final isSelected = cat == selected;
          final icon = AppConstants.categoryIcons[cat] ?? Icons.apps;
          final color = AppConstants.categoryColors[cat] ?? AppConstants.accentColor;

          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.accentColor : AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppConstants.accentColor : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppConstants.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
