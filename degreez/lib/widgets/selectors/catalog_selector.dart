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
  List<String> _faculties = [];
  String? selectedCatalog;

  

  @override
  void initState() {
    super.initState();
    _loadItemsFromFile();
  }

  Future<void> _loadItemsFromFile() async {
    final data = await rootBundle.loadString(
      'assets/catalogsList.txt',
    );
    List<String> lines =
        data
            .split('\n')
            .map((line) => line.trim())
            .toList();  

    setState(() {
      _faculties = lines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      iconEnabledColor: AppColorsDarkMode.secondaryColor,
      value: selectedCatalog,
      style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
      decoration: InputDecoration(
        labelText: 'Catalog',
        labelStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDarkMode.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDarkMode.secondaryColor),
        ),
        filled: true,
        fillColor: AppColorsDarkMode.surfaceColor,
      ),
      dropdownColor: AppColorsDarkMode.surfaceColor,
      items:
          _faculties.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedCatalog = value;
            context.read<SignUpProvider>().setSelectedCatalog(value);
          });
        }
      },
    );
  }
}
