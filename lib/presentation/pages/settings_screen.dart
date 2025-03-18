import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todosync/config/theme.dart';
import 'package:todosync/config/theme_manager.dart';
import 'package:todosync/main.dart';
import 'package:todosync/presentation/pages/login_screen.dart';
import 'package:todosync/presentation/widgets/custom_button.dart';
import 'package:todosync/presentation/widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String? _newPassword;
  String? _confirmPassword;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDarkModeSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      setState(() {
        _notificationsEnabled =
            settings.authorizationStatus == AuthorizationStatus.authorized;
      });
    } catch (e) {
      // Ignorar errores
    }
  }

  Future<void> _loadDarkModeSettings() async {
    final brightness = MediaQuery.of(context).platformBrightness;
    setState(() {
      _darkModeEnabled = brightness == Brightness.dark;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Actualizar en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'name': _nameController.text.trim()},
      );

      // Actualizar en Auth
      await user.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar perfil: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      if (_notificationsEnabled) {
        // No podemos desactivar notificaciones programáticamente,
        // solo mostrar instrucciones al usuario
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Desactivar notificaciones'),
                content: const Text(
                  'Para desactivar las notificaciones, ve a la configuración de tu dispositivo, '
                  'busca esta aplicación y desactiva los permisos de notificación.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
        );
      } else {
        // Solicitar permisos
        final settings = await FirebaseMessaging.instance.requestPermission();
        setState(() {
          _notificationsEnabled =
              settings.authorizationStatus == AuthorizationStatus.authorized;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar notificaciones: $e')),
      );
    }
  }

  Future<void> _toggleDarkMode() async {
    setState(() {
      _darkModeEnabled = !_darkModeEnabled;
    });

    // Implementar cambio de tema
    if (_darkModeEnabled) {
      ThemeManager.of(context).changeTheme(AppTheme.darkTheme);
    } else {
      ThemeManager.of(context).changeTheme(AppTheme.lightTheme);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cambiar contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                  obscureText: true,
                  onChanged: (value) => _newPassword = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                  obscureText: true,
                  onChanged: (value) => _confirmPassword = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (_newPassword == _confirmPassword) {
                    try {
                      await user.updatePassword(_newPassword!);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña actualizada correctamente'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar contraseña: $e'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las contraseñas no coinciden'),
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay datos para exportar')),
        );
        return;
      }

      // Crear archivo Excel
      final excel = Excel.createExcel();
      final sheet = excel['Tareas'];

      // Agregar encabezados
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Título'),
        TextCellValue('Descripción'),
        TextCellValue('Estado'),
      ]);

      // Agregar datos
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        sheet.appendRow([
          TextCellValue(doc.id),
          TextCellValue(data['title'] ?? 'Sin título'),
          TextCellValue(data['description'] ?? 'Sin descripción'),
          TextCellValue(
            data['isCompleted'] == true ? 'Completada' : 'Pendiente',
          ),
        ]);
      }

      // 📂 Obtener directorio de Descargas y pedir permisos en Android
      Directory? directory;
      if (Platform.isAndroid) {
        if (await _requestStoragePermission()) {
          directory = Directory(
            '/storage/emulated/0/Download',
          ); // Carpeta Descargas
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permiso denegado. No se puede guardar el archivo.',
              ),
            ),
          );
          return;
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el directorio de almacenamiento'),
          ),
        );
        return;
      }

      final filePath = '${directory.path}/tareas.xlsx';

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Datos exportados en: $filePath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al exportar datos: $e')));
    }
  }

  // Función para pedir permisos de almacenamiento en Android
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true; // Permiso concedido
      } else if (await Permission.manageExternalStorage.request().isGranted) {
        return true; // Permiso concedido en Android 11+
      }
    }
    return false; // Permiso denegado
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔹 Guardar referencia segura al contexto
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(); // Cerrar el diálogo antes de continuar

                  try {
                    // 🔒 Reautenticar antes de eliminar la cuenta
                    final credential = await _reauthenticateUser(user, context);
                    if (credential == null) return;

                    // 🗑️ Eliminar datos del usuario en Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete();

                    // 🚀 Eliminar la cuenta de Firebase Authentication
                    await user.delete();

                    // 🏁 Cerrar sesión manualmente antes de redirigir
                    await FirebaseAuth.instance.signOut();

                    // ✅ Redirigir al login con la referencia guardada
                    navigator.pushReplacementNamed('/login');
                  } catch (e) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar la cuenta: $e'),
                      ),
                    );

                    // 🔄 Intentar redirigir al login incluso si hay error
                    navigator.pushReplacementNamed('/login');
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // 🔒 Función para reautenticar al usuario antes de eliminar la cuenta
  Future<AuthCredential?> _reauthenticateUser(
    User user,
    BuildContext context,
  ) async {
    try {
      final providerData = user.providerData.first;

      if (providerData.providerId == 'password') {
        // Si el usuario inició sesión con email y contraseña
        final email = user.email!;
        final password = await _askForPassword(context);
        if (password == null) return null;

        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return credential;
      } else if (providerData.providerId == 'google.com') {
        // Si el usuario inició sesión con Google
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null; // Si cancela el inicio de sesión

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
        return credential;
      } else {
        // Para otros proveedores como Facebook, Apple, etc.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes volver a iniciar sesión para eliminar tu cuenta',
            ),
          ),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de autenticación: $e')));
      return null;
    }
  }

  // 📌 Pedir contraseña al usuario en un diálogo
  Future<String?> _askForPassword(BuildContext context) async {
    String? password;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar contraseña'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  password = controller.text;
                  Navigator.of(context).pop();
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Nombre',
                      hint: 'Tu nombre completo',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Guardar cambios',
                      onPressed: _updateProfile,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Preferencias',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSwitchItem(
                      'Notificaciones',
                      'Recibe alertas sobre tus tareas',
                      _notificationsEnabled,
                      _toggleNotifications,
                    ),
                    const Divider(),
                    _buildSwitchItem(
                      'Modo oscuro',
                      'Cambia el tema de la aplicación',
                      _darkModeEnabled,
                      _toggleDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Seguridad', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildActionItem(
                      'Cambiar contraseña',
                      'Actualiza tu contraseña de acceso',
                      Icons.lock,
                      _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Datos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildActionItem(
                      'Exportar datos',
                      'Descarga todas tus tareas',
                      Icons.download,
                      _exportData,
                    ),
                    const Divider(),
                    _buildActionItem(
                      'Eliminar cuenta',
                      'Elimina tu cuenta y todos tus datos',
                      Icons.delete_forever,
                      _deleteAccount,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDestructive
                        ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isDestructive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          isDestructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
