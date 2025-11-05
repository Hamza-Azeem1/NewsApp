import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import 'admin_sign_in_screen.dart';

/// Guards the admin area:
/// - If not signed in -> shows sign-in
/// - If signed in but no 'admin' custom claim -> "Not authorized"
/// - If signed in and admin -> AdminDashboard
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) {
          return const AdminSignInScreen();
        }
        // Refresh token to get latest custom claims.
        return FutureBuilder(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnap) {
            if (tokenSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final isAdmin = tokenSnap.data?.claims?['admin'] == true;
            if (!isAdmin) {
              return Scaffold(
                appBar: AppBar(title: const Text('Admin')),
                body: const Center(
                  child: Text('Not authorized. Ask the owner to grant admin access.'),
                ),
              );
            }
            return const AdminDashboard();
          },
        );
      },
    );
  }
}
