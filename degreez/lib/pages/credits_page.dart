import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


showCreditsPage(context){
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  String credit ='''
  2025
  
  Developers:
  © Moamen Kassem
  © Ramzy Ayan
  https://www.linkedin.com/in/ramzyAyan
  © Ibraheem Akaree

  Logo Designer:
  © Moamen Kassem 
  (this Logo is specifically made for this app please do not use it anywhere else)
  
  Huge thanks to Michael maltsev who provided open source synchronized data of SAP Technion courses

  This program was developed under the provision of Technion's Android course

  ''';

  var image =  themeProvider.isDarkMode ? Image.asset('assets/Logo_DarkMode3.png') : Image.asset('assets/Logo3.png');
  
  showLicensePage(
    context: context,
    applicationIcon:SizedBox(
                            width: 250,
                            height: 250,
                            child:image, 
                          ),
    applicationName: 'DegreEZ',
    applicationVersion: '1.0.0',
    applicationLegalese: credit,
  );
}