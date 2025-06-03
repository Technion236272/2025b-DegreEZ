import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';


textFormFieldWithStyle({
  required String label,
  required TextEditingController controller,
  required String example,
  RegExp? validatorRegex,
  int? lineNum,
  String? errorMessage,
}) {
  return Padding(
    padding: EdgeInsets.only(top: 10, bottom: 10),
    child: TextFormField(
      textAlign: TextAlign.start,
      maxLines: lineNum ?? 1,
      controller: controller,
      cursorColor: AppColorsDarkMode.secondaryColor,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.secondaryColor,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.secondaryColorDimDD),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.errorColor,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.errorColorDim),
        ),
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColor),
        hoverColor: AppColorsDarkMode.secondaryColor,
        hintText: example,
        hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
      ),
      style: TextStyle(color: AppColorsDarkMode.secondaryColor, fontSize: 15),
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
        }

        return null; // Input is valid
      },
    ),
  );
}