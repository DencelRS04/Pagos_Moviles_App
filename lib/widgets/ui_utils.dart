import 'package:flutter/material.dart';

class UIUtils {
  // Snackbar/Toast reutilizable
  static void showMsg(
    BuildContext context,
    String text, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Diálogo de confirmación reutilizable
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("ACEPTAR"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
