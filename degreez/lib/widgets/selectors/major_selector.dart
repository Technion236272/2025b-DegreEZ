import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

class MajorSelector extends StatefulWidget {
  const MajorSelector({super.key});

  @override
  State<MajorSelector> createState() => _MajorSelectorState();
}

class _MajorSelectorState extends State<MajorSelector> {
  List<String> _majors = [];
  String? selectedMajor;
  bool isLoading = false;
  String? lastLoadedFaculty;
  String? lastLoadedCatalog;

  @override
  void initState() {
    super.initState();
    // Load majors after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpProvider = context.read<SignUpProvider>();
      final faculty = signUpProvider.selectedFaculty;
      final catalog = signUpProvider.selectedCatalog;
      if (faculty != null && catalog != null) {
        _loadItemsFromFile(catalog, faculty);
      }
    });
  }

  Future<void> _loadItemsFromFile(String catalog, String faculty) async {
    if ((faculty == lastLoadedFaculty && catalog == lastLoadedCatalog) || isLoading) {
      return; // Avoid reloading the same catalog/faculty combination or loading while already loading
    }

    setState(() {
      isLoading = true;
      selectedMajor = null; // Reset selection when catalog or faculty changes
    });

    try {
      final data = await rootBundle.loadString(
        'assets/Faculties$catalog/$faculty.txt',
      );
      
      List<String> lines = data.split('\n').map((line) => line.trim()).toList();

      // Find the start of majors section
      int majorsStartIndex = lines.indexOf('מסלולים:');
      if (majorsStartIndex == -1) {
        // Handle case where the marker is not found
        setState(() {
          _majors = [];
          isLoading = false;
          lastLoadedFaculty = faculty;
          lastLoadedCatalog = catalog;
        });
        return;
      }

      // Find the end of majors section (empty line or end of file)
      int majorsEndIndex = lines.indexWhere(
        (val) => val.isEmpty,
        majorsStartIndex + 1,
      );
      
      if (majorsEndIndex == -1) {
        majorsEndIndex = lines.length;
      }

      List<String> majors = lines.sublist(
        majorsStartIndex + 1,
        majorsEndIndex,
      ).where((major) => major.isNotEmpty).toList(); // Filter out empty strings

      setState(() {
        _majors = majors;
        isLoading = false;
        lastLoadedFaculty = faculty;
        lastLoadedCatalog = catalog;
      });
    } catch (e) {
      // Handle file loading error
      debugPrint('Error loading majors for catalog $catalog, faculty $faculty: $e');
      setState(() {
        _majors = [];
        isLoading = false;
        lastLoadedFaculty = faculty;
        lastLoadedCatalog = catalog;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, _) {
        selectedMajor = context.read<SignUpProvider>().selectedMajor;
        final currentFaculty = signUpProvider.selectedFaculty;
        final currentCatalog = signUpProvider.selectedCatalog;
        
        // Load majors if catalog or faculty has changed
        if (currentFaculty != null && 
            currentCatalog != null && 
            (currentFaculty != lastLoadedFaculty || currentCatalog != lastLoadedCatalog) && 
            !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadItemsFromFile(currentCatalog, currentFaculty);
          });
        }

        // Determine if dropdown should be enabled
        bool isEnabled = currentFaculty != null && 
                        currentCatalog != null && 
                        _majors.isNotEmpty && 
                        !isLoading;

        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: _majors.contains(selectedMajor) ? selectedMajor : null,
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
        labelText: "Major",
        labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColor),
        hoverColor: AppColorsDarkMode.secondaryColor,
        hintText: currentCatalog == null 
                          ? 'Please select catalog first'
                          : currentFaculty == null 
                              ? 'Please select faculty first'
                              : isLoading 
                                  ? 'Loading...'
                                  : _majors.isEmpty
                                      ? 'No majors available'
                                      : 'Please Select Your Major',
        hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
      ),
          dropdownColor: AppColorsDarkMode.surfaceColor,
          items: _majors.isEmpty
              ? [
                  DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text(
                      currentCatalog == null 
                          ? 'Please select catalog first'
                          : currentFaculty == null 
                              ? 'Please select faculty first'
                              : isLoading 
                                  ? 'Loading...'
                                  : 'No majors available',
                      style: TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                    ),
                  ),
                ]
              : _majors.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7, // Constrain width
                      child: AutoSizeText(
                        item,
                        maxFontSize: 15,
                        minFontSize: 8,
                        maxLines: 2, // Allow text to wrap to 2 lines if needed
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          onChanged: isEnabled
              ? (value) {
                  setState(() {
                    selectedMajor = value;
                  });
                  // Update the provider with selected major
                  if (value != null) {
                    signUpProvider.setSelectedMajor(value);
                  }
                }
              : null,
        validator: (value) =>
        (value == null || value.isEmpty) && isEnabled ? "Can't leave your major empty :)" : null,
        );
      },
    );
  }
}