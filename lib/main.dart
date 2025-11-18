import 'package:flutter/material.dart';
import 'package:my_notebook/services/auth/auth_service.dart';
import 'package:my_notebook/views/login_view.dart';
import 'package:my_notebook/views/notes/new_note_view.dart';
import 'package:my_notebook/views/notes/notes_view.dart';
import 'package:my_notebook/views/register_view.dart';
import 'package:my_notebook/views/verify_email_view.dart';
import 'package:my_notebook/constants/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'My Flutter App',
    theme: ThemeData(
      primarySwatch: Colors.blue, 
    ),
    home: const HomePage(title: 'Home Page'),
    routes: {
      loginRoute: (context) => const LoginView(),
      registerRoute: (context) => const RegisterView(),
      notesRoute: (context) => const NotesView(),
      verifyEmailRoute: (context) => const VerifyEmailView(),
      newNoteRoute: (context) => const NewNoteView(),
    },
  ));
}

class HomePage extends StatelessWidget   {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
     return FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if(user != null) {
                if (user.isEmailVerified) {
                  return const NotesView();
                } else {
                  return const VerifyEmailView();
                }
              } else {
                return const LoginView();
              }

            default:
              return const CircularProgressIndicator();

          } 

      },
    );
  }
}










