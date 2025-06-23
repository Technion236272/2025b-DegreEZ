import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
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
    selectedCatalog = context.read<SignUpProvider>().selectedCatalog;
    return DropdownButtonFormField<String>(
      iconEnabledColor: const Color.fromRGBO(184, 199, 214, 1),
      value: _catalogs.contains(selectedCatalog) ? selectedCatalog : null,
      style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
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
        labelText: "Catalog",
        labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColor),
        hoverColor: AppColorsDarkMode.secondaryColor,
        hintText: "Please Select Catalog Year",
        hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
      ),
      dropdownColor: AppColorsDarkMode.surfaceColor,
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
      validator: (value) =>
        (value == null || value.isEmpty) ? "can't leave this one empty ;)" : null,
    );
  }
}
