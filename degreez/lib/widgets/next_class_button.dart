import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class NextClassButton extends StatelessWidget {
  final String courseName;
  final String? sessionType;
  final String buildingName;
  final String roomNumber;
  final Color courseColor;
  final VoidCallback onTap;
  final ThemeProvider themeProvider;

  const NextClassButton({
    super.key,
    required this.courseName,
    this.sessionType,
    required this.buildingName,
    required this.roomNumber,
    required this.courseColor,
    required this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(25),
      color: courseColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [
                courseColor,
                courseColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: themeProvider.surfaceColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: themeProvider.surfaceColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next Class',
                    style: TextStyle(
                      color: themeProvider.surfaceColor.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    buildingName,
                    style: TextStyle(
                      color: themeProvider.surfaceColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: themeProvider.surfaceColor.withOpacity(0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
