// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/login_notifier.dart';

// /// A widget to display user information and sign out button
// class UserSignInWidget extends StatelessWidget {
//   const UserSignInWidget({super.key});
  

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text(
//           'Welcome',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'Please sign in with your Google account to continue',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.grey),
//         ),
//         const SizedBox(height: 32),
//         GoogleSignInButton(
//           onSignInComplete: () {
//             // Show success message
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Successfully signed in!'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           },
//         ),
//         if (loginNotifier.isLoading)
//           const Padding(
//             padding: EdgeInsets.only(top: 16.0),
//             child: Text(
//               'Signing in...',
//               style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
//             ),
//           ),
//       ],
//     );
//   }
// }
