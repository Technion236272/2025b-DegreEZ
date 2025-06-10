import 'package:flutter/material.dart';


showCreditsPage(context){
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