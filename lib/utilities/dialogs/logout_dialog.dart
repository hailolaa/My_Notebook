import 'package:flutter/material.dart';
import 'package:my_notebook/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Logout',
    content: 'Are you sure you want to logout?',
    positiveButtonText: 'Logout',
    negativeButtonText: 'Cancel',
    optionsBuilder: () => {
      'Logout': true,
      'Cancel': false,
    },
  ).then((value) => value ?? false
  );
}