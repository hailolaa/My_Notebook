import 'package:flutter/material.dart';
import 'package:my_notebook/constants/routes.dart';
import 'package:my_notebook/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  _VerifyEmailViewState createState() => _VerifyEmailViewState();
}
class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
      ),
      body: Column(
        children : [
          const Text("A verification email has been sent to your email address."),
          const SizedBox(height: 16),
          const Text("If you haven't received the email yet, press the button below to resend it."),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
             
            },
            child: const Text("Resend Verification Email"),
          ),
          TextButton(onPressed: () async {
            await AuthService.firebase().logout();
            Navigator.of(context).pushNamedAndRemoveUntil(registerRoute, (_) => false);
          }, child: const Text("Restart"))
        ],
      ),    
    );
  }
}