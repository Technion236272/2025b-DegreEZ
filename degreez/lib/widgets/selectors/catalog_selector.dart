import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

class CatalogSelector extends StatefulWidget {
  const CatalogSelector({super.key});

  @override
  State<CatalogSelector> createState() => _CatalogSelectorState();
}

class _CatalogSelectorState extends State<CatalogSelector> {
  List<String> _catalogs = [];
  String? selectedCatalog;

  @override
  void initState() {
    super.initState();
    _loadItemsFromFile();
  }

  Future<void> _loadItemsFromFile() async {
    final data = await rootBundle.loadString('assets/catalogsList.txt');
    List<String> lines = data.split('\n').map((line) => line.trim()).toList();

    setState(() {
      _catalogs = lines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SignUpProvider, ThemeProvider>(
      builder: (context, signUpProvider, themeProvider, _) {
        selectedCatalog = signUpProvider.selectedCatalog;
        return DropdownButtonFormField<String>(
          iconEnabledColor: themeProvider.secondaryColor,
          value: _catalogs.contains(selectedCatalog) ? selectedCatalog : null,
          style: TextStyle(color: themeProvider.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeProvider.surfaceColor,
            labelText: "Catalog",
            labelStyle: TextStyle(
              color: themeProvider.primaryColor,
              fontSize: 15,
            ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeProvider.borderPrimary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: themeProvider.borderPrimary,
                        width: 2.0,

          ),          
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeProvider.errorColor,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeProvider.errorColor.withAlpha(170)),
        ),
        alignLabelWithHint: true,
        hoverColor: themeProvider.secondaryColor,
            hintText: "Please Select Catalog Year",
        hintStyle: TextStyle(color: themeProvider.secondaryColor.withAlpha(200),
      ),),

          dropdownColor: themeProvider.surfaceColor,
          items:
              _catalogs.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedCatalog = value;
                context.read<SignUpProvider>().setSelectedCatalog(value);
              });
            }
            context.read<SignUpProvider>().resetFaculty();
            context.read<SignUpProvider>().resetMajor();
          },
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? "can't leave this one empty ;)"
                      : null,
        );
      },
    );
  }
}
