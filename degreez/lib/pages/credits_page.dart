import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

showCreditsPage(context) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  var image = themeProvider.isDarkMode 
      ? Image.asset('assets/Logo_DarkMode3.png') 
      : Image.asset('assets/Logo3.png');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: image,
            ),
            const SizedBox(width: 10),
            const Text('DegreEZ v3.0.0'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Developers Section
              const Text(
                'Developers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '© Ibraheem Akaree',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://github.com/ibraheemak');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'GitHub',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Divider
              Divider(
                height: 20,
                thickness: 1,
                color: Colors.grey[300],
                indent: 20,
                endIndent: 20,
              ),
              
              const Text(
                '© 𝐑𝐚𝐦𝐳𝐲 𝐀𝐲𝐚𝐧\n',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Maintained and developed Solely by me since July 2025.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                ),
                const SizedBox(height: 5), 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse('https://www.linkedin.com/in/ramzyAyan');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'LinkedIn',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Text(' | '),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse('https://github.com/RamzyAyan');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'GitHub',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Divider
              Divider(
                height: 20,
                thickness: 1,
                color: Colors.grey[300],
                indent: 20,
                endIndent: 20,
              ),
              
              const Text(
                '© Moamen Kassem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse('https://www.linkedin.com/in/moamen-kassem-213bb2395');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'LinkedIn',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Text(' | '),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse('https://github.com/MoamenKassem');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'GitHub',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
                            // Divider
              Divider(
                height: 20,
                thickness: 1,
                color: Colors.grey[300],
                indent: 20,
                endIndent: 20,
              ),
              // Course Info
              Text(
                'This application started its development under the provision of Technion\'s Android course april 2025 - july 2025.\n\n',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show the full license page with all Flutter dependencies
              showLicensePage(
                context: context,
                applicationIcon: SizedBox(
                  width: 250,
                  height: 250,
                  child: image,
                ),
                applicationName: 'DegreEZ',
                applicationVersion: '1.0.0',
                applicationLegalese: '''Logo Designer:
© Moamen Kassem
(this Logo is specifically made for this app please do not use it anywhere else)

Additional licenses for Flutter and packages are listed below.''',
              );
            },
            child: const Text('View All Licenses'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}