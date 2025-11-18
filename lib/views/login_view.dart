import 'package:flutter/material.dart';
import 'package:my_notebook/constants/routes.dart';
import 'package:my_notebook/services/auth/auth_exceptions.dart';
import 'package:my_notebook/services/auth/auth_service.dart';
import 'package:my_notebook/utilities/dialogs/error_dialogs.dart';


class LoginView extends StatefulWidget {
  const LoginView({super.key});


  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                AuthService.firebase().login(
                  email: email,
                  password: password,
                );
                final user = AuthService.firebase().currentUser;
                if (user?.isEmailVerified?? false) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    notesRoute, 
                  (route) => false);
                  return;
                }else{
                  Navigator.of(context).pushNamed(
                    verifyEmailRoute
                  );
                }

              } on UserNotFoundAuthException  {
                  await showErrorDialog(
                    context, 
                    'No user found for that email.'
                    );
                } on WrongPasswordAuthException {
                  await showErrorDialog(
                    context, 
                    'Wrong password provided for that user.'
                    );
                } on GenericAuthException {
                  await showErrorDialog(
                    context, 
                    'Authentication error.'
                    );
                }
            },
          child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(registerRoute, (route) => false);
            },
            child: const Text('Not registered yet? Register here!'),
          ),
        ],
      ),
    );
  } 

    
}

 