import 'package:flutter/material.dart';
import 'package:my_notebook/utilities/dialogs/generic_dialog.dart';

Future<void> showErrorDialog(BuildContext context, String message) {
  return showGenericDialog(
    context: context,
    title: 'Error',
    content: message,
    positiveButtonText: 'OK',
    negativeButtonText: 'Cancel',
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
