import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../color/color_palette.dart';


Widget textFormFieldWithStyle({
  required String label,
  required TextEditingController controller,
  required String example,
  RegExp? validatorRegex,
  int? lineNum,
  String? errorMessage,
  required BuildContext context, // Add context parameter to access provider
}) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: TextFormField(
          textAlign: TextAlign.start,
          maxLines: lineNum ?? 1,
          controller: controller,
          cursorColor: themeProvider.primaryColor,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeProvider.isLightMode ? themeProvider.borderPrimary : themeProvider.accentColor,
          ),
        ),
            focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: themeProvider.isLightMode ? themeProvider.borderPrimary : themeProvider.accentColor,
                        width: 2.0,

          ),          
        ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: themeProvider.isDarkMode 
                  ? AppColorsDarkMode.errorColor
                  : AppColorsLightMode.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: themeProvider.isDarkMode 
                  ? AppColorsDarkMode.errorColorDim
                  : AppColorsLightMode.errorColor.withOpacity(0.7),
              ),
            ),
            alignLabelWithHint: true,
            labelText: label,
            labelStyle: TextStyle(color: themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor ,),
            hoverColor: themeProvider.primaryColor,
            hintText: example,
            hintStyle: TextStyle(color: themeProvider.textSecondary.withOpacity(0.7)),
          ),
          style: TextStyle(color: themeProvider.textPrimary, fontSize: 15),
      validator: (value) {
        if (value == null) {
          return 'This field is required.';
        }
        
        validatorRegex ??= RegExp(r'^.?$');

        if (!validatorRegex!.hasMatch(value)) {
          debugPrint("value = $value");
          if (value == '') {
            return 'This field is required.';
          }
          return errorMessage ?? 'Invalid Input';
        }        return null; // Input is valid
      },
    ),
      );
    },
  );
}