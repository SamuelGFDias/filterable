import 'package:flutter/material.dart';

class ModalFooter extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const ModalFooter({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FooterButton(
                icon: Icons.highlight_off,
                color: Colors.red,
                tooltip: 'Cancelar',
                onPressed: onCancel,
              ),
              _FooterButton(
                icon: Icons.check,
                color: Colors.green,
                tooltip: 'Confirmar',
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _FooterButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: onPressed != null ? color : Colors.grey),
        onPressed: onPressed,
      ),
    );
  }
}

