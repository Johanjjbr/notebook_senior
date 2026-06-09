import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/theme_provider.dart';
import '../l10n/app_localizations.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withAlpha(30),
                    child: Icon(Icons.person, size: 30, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName.isNotEmpty ? auth.displayName : l10n.user,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.user?.email ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.editProfile, style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.changeName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _mostrarDialogoNombre(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.changeEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _mostrarDialogoEmail(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.changePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _mostrarDialogoPassword(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.appearance, style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: Icon(themeProvider.isDark ? Icons.dark_mode : Icons.light_mode),
              title: Text(l10n.darkMode),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.information, style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.version),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(l10n.developedWith),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text(l10n.logoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.logout),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<AuthProvider>().logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _mostrarDialogoNombre(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final controller = TextEditingController(text: auth.displayName);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.changeName),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: l10n.nameLabel,
          hintText: l10n.nameHint,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            await auth.cambiarNombre(controller.text.trim());
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.nameUpdated)),
              );
            }
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

void _mostrarDialogoEmail(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final controller = TextEditingController(text: auth.user?.email ?? '');

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.changeEmail),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: l10n.newEmailLabel,
        ),
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            final error = await auth.cambiarEmail(controller.text.trim());
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? l10n.emailUpdated)),
              );
            }
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

void _mostrarDialogoPassword(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.changePassword),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: l10n.newPasswordLabel,
              ),
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? l10n.passwordMinLength : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: l10n.confirmPasswordLabel,
              ),
              obscureText: true,
              validator: (v) =>
                  v != passwordController.text ? l10n.passwordMismatch : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final error = await auth.cambiarPassword(passwordController.text);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? l10n.passwordUpdated)),
              );
            }
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}
