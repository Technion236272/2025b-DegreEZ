import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

enum DirectionValues { horizontal, vertical }

class CourseCard extends StatefulWidget {
  final String courseId;
  final String courseName;
  final double creditPoints;
  final String finalGrade;
  final dynamic colorPalette;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.creditPoints,
    required this.finalGrade,
    required this.colorPalette,
    this.onTap,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: widget.colorPalette.cardBG(widget.courseId),
        child: Column(
          children: [
            // Card Top Bar (Course number and points)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.colorPalette.topBarBG,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Text(
                          widget.courseId,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.colorPalette.topBarText,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.creditPoints > 0)
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.colorPalette.topBarMarkBG,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Icon(
                                    Icons.school,
                                    size: 8,
                                    color: widget.colorPalette.topBarMarkText,
                                  ),
                                ),
                                Expanded(
                                  flex: 9,
                                  child: Text(
                                    widget.creditPoints % 1 == 0 
                                        ? widget.creditPoints.toInt().toString()
                                        : widget.creditPoints.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: widget.colorPalette.topBarMarkText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Course Name and Grade
            Expanded(
              flex: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Course Name
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: AutoSizeText(
                          widget.courseName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          minFontSize: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    // Grade Display
                    if (widget.finalGrade.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: widget.colorPalette.gradeBG,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              widget.finalGrade,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: widget.colorPalette.gradeText,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
