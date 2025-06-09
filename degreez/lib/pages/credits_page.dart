import 'package:flutter/material.dart';


showCreditsPage(context){
  String credit ='''
  2025
  
  Developers:
  © Moamen Kassem
  © Ramzy Ayan
  © Ibraheem Akaree

  Logo Designer:
  © Moamen Kassem 
  (this Logo is specifically made for this app please do not use it anywhere else)
  
  
  ''';
  
  showLicensePage(
    context: context,
    applicationIcon:SizedBox(
                            width: 250,
                            height: 250,
                            child: Image.asset('assets/Logo_DarkMode2.png'),
                          ),
    applicationName: 'DegreEZ',
    applicationVersion: '1.0.0',
    applicationLegalese: credit,
  );
}