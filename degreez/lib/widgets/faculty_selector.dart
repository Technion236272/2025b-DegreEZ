import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class FacultySelector extends StatefulWidget {
  const FacultySelector({super.key});

  @override
  State<FacultySelector> createState() => _FacultySelectorState();
}

class _FacultySelectorState extends State<FacultySelector> {
  List<String> _faculties = [];
  String? selectedFaculty;

  @override
  void initState() {
    super.initState();
    _loadItemsFromFile();
  }

  Future<void> _loadItemsFromFile() async {
    final data = await rootBundle.loadString(
      'assets/Faculties2025/מדעי המחשב.txt',
    );
    List<String> lines =
        data
            .split('\n')
            .map((line) => line.trim())
            .toList();

    List<String> Facultys = lines.sublist(lines.indexOf('מסלולים:')+1,lines.indexWhere((val){return val=="";},lines.indexOf('מסלולים:')));
  

    setState(() {
      _faculties = Facultys;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      iconEnabledColor: AppColorsDarkMode.secondaryColor,
      value: selectedFaculty,
      style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
      decoration: InputDecoration(
        labelText: 'Faculty',
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
            selectedFaculty = value;
          });
        }
      },
    );
  }

  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/Faculties2025/מדעי המחשב.txt');
  }
}
