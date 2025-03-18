import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y Soporte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Necesitas ayuda?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí tienes algunas formas de obtener soporte:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: const Text('Contactar por correo'),
              subtitle: const Text('support@todosync.com'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.forum, color: Theme.of(context).colorScheme.primary),
              title: const Text('Foro de la comunidad'),
              subtitle: const Text('Visita nuestro foro de ayuda'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
              title: const Text('FAQ - Preguntas Frecuentes'),
              subtitle: const Text('Respuestas a las dudas más comunes'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
