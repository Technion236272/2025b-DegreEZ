import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

class FacultySelector extends StatefulWidget {
  const FacultySelector({super.key});

  @override
  State<FacultySelector> createState() => _FacultySelectorState();
}

class _FacultySelectorState extends State<FacultySelector> {
  List<String> _faculties = [];
  String? selectedFaculty;
  bool isLoading = false;
  String? lastLoadedCatalog;

  @override
  void initState() {
    super.initState();
    // Load faculties after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<SignUpProvider>().selectedCatalog;
      if (catalog != null) {
        _loadItemsFromFile(catalog);
      }
    });
  }

  Future<void> _loadItemsFromFile(String catalog) async {
    if (catalog == lastLoadedCatalog || isLoading) {
      return; // Avoid reloading the same catalog or loading while already loading
    }

    setState(() {
      isLoading = true;
      selectedFaculty = null; // Reset selection when catalog changes
    });

    try {
      final data = await rootBundle.loadString(
        'assets/$catalog.txt',
      );
      
      List<String> lines = data.split('\n').map((line) => line.trim()).toList();

      setState(() {
        _faculties = lines;
        isLoading = false;
        lastLoadedCatalog = catalog;
      });
    } catch (e) {
      // Handle file loading error
      debugPrint('Error loading faculties for catalog $catalog: $e');
      setState(() {
        _faculties = [];
        isLoading = false;
        lastLoadedCatalog = catalog;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, _) {
        final currentCatalog = signUpProvider.selectedCatalog;
        
        // Load faculties if catalog has changed
        if (currentCatalog != null && currentCatalog != lastLoadedCatalog && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadItemsFromFile(currentCatalog);
          });
        }

        // Determine if dropdown should be enabled
        bool isEnabled = currentCatalog != null && _faculties.isNotEmpty && !isLoading;

        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: selectedFaculty,
          style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
          decoration: InputDecoration(
            labelText: isLoading ? 'Loading faculties...' : 'Faculty',
            labelStyle: const TextStyle(
              color: AppColorsDarkMode.secondaryColorDim,
            ),
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
          items: _faculties.isEmpty
              ? [
                  DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text(
                      currentCatalog == null 
                          ? 'Please select catalog first'
                          : isLoading 
                              ? 'Loading...'
                              : 'No faculties available',
                      style: TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                    ),
                  ),
                ]
              : _faculties.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
          onChanged: isEnabled
              ? (value) {
                  setState(() {
                    selectedFaculty = value;
                  });
                  // Update the provider with selected faculty
                  if (value != null) {
                    signUpProvider.setSelectedFaculty(value);
                  }
                }
              : null,
        );
      },
    );
  }
}