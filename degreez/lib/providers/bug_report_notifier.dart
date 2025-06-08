import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class BugReportNotifier extends ChangeNotifier {
  bool _isLoading= false;
  bool _status = false;
  
  
  bool get isLoading => _isLoading;
  bool get status => _status;
  
  void setIsLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> reportBug({required context,required title,required description}) async {
    _isLoading = true;
    
    notifyListeners();
    try {
                await FirebaseFirestore.instance.collection('bug_reports').doc('bug $title').set({
                  'description': description,
                  'timestamp': DateTime.now(),
                });
                _status = true;
                notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bug report submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _status = false;
                notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to submit bug report: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              finally{
              _isLoading = false;
              notifyListeners();
              
              }    
  }

}