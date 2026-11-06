import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef UsersPayload = ({List<AdminUser> users, List<String> roles, AdminUsage usage});

class AdminUsersViewModel extends AdminSectionViewModel<UsersPayload> {
  String role = '';

  @override
  Future<UsersPayload> fetch(String token) => api.users(token, role: role);

  void setRole(String value) {
    role = value;
    load();
  }
}

/// Login accounts and what each one may do.
///
/// Granting the super admin role is refused by the API unless the person
/// doing it is one; the screen does not hide the option, because a silent
/// omission teaches nobody why — the server's own message does.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUsersViewModel(),
      child: const CareTheme(child: _UsersView()),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  Future<void> _addOrEdit(BuildContext context, AdminUsersViewModel viewModel, List<String> roles, [AdminUser? user]) async {
    final creating = user == null;
    final values = await careFormSheet(
      context,
      title: creating ? 'Add user' : 'Edit ${user.name}',
      fields: [
        CareFormField('name', 'Full name', initial: user?.name, required: true, icon: Icons.person_outline),
        CareFormField('email', 'Email', initial: user?.email, required: true,
            keyboard: TextInputType.emailAddress, icon: Icons.mail_outline),
        CareFormField('phone', 'Phone', initial: user?.phone, keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        CareFormField('role', 'Role', initial: user?.role, required: true, options: roles, icon: Icons.badge_outlined),
        if (creating)
          const CareFormField('password', 'Password', required: true, icon: Icons.lock_outline),
      ],
    );
    if (values == null || !context.mounted) return;

    if (creating) values['password_confirmation'] = values['password'];

    final error = await viewModel.mutate((api, token) =>
        creating ? api.userStore(token, values) : api.userUpdate(token, user.id, values));
    if (context.mounted) {
      careSnack(context, error ?? (creating ? 'User created.' : 'User updated.'), isError: error != null);
    }
  }

  Future<void> _resetPassword(BuildContext context, AdminUsersViewModel viewModel, AdminUser user) async {
    final values = await careFormSheet(
      context,
      title: 'New password for ${user.name}',
      submitLabel: 'Reset password',
      fields: const [CareFormField('password', 'New password', required: true, icon: Icons.lock_reset_outlined)],
    );
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.userResetPassword(token, user.id, values['password'] as String));
    if (context.mounted) careSnack(context, error ?? 'Password reset.', isError: error != null);
  }

  Future<void> _delete(BuildContext context, AdminUsersViewModel viewModel, AdminUser user) async {
    final yes = await careConfirm(context,
        title: 'Delete ${user.name}?',
        message: 'They will not be able to sign in again. Records they created stay as they are.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.userDestroy(token, user.id));
    if (context.mounted) careSnack(context, error ?? 'User deleted.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminUsersViewModel>();
    final users = viewModel.data?.users ?? const <AdminUser>[];
    final roles = viewModel.data?.roles ?? const <String>[];
    final usage = viewModel.data?.usage;

    return AdminSectionScaffold(
      title: 'User Management',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: users.length,
      onRefresh: viewModel.load,
      createLabel: 'Add user',
      onCreate: roles.isEmpty ? null : () => _addOrEdit(context, viewModel, roles),
      emptyIcon: Icons.manage_accounts_outlined,
      emptyTitle: 'No accounts match',
      emptyMessage: 'Try another role, or add the first account for this one.',
      header: Column(
        children: [
          if (usage != null)
            AdminStatRow(stats: [
              AdminStat(value: '${users.length}', label: 'Listed'),
              AdminStat(value: usage.isUnlimited ? '∞' : '${usage.limit}', label: 'Plan seats'),
              AdminStat(value: '${usage.used}', label: 'Used'),
            ]),
          AdminFilterChips(
            value: viewModel.role,
            onChanged: viewModel.setRole,
            options: [
              (value: '', label: 'All'),
              for (final r in roles) (value: r, label: r.replaceAll('_', ' ')),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final user = users[i];
        return AdminCard(
          title: user.name,
          subtitle: user.email,
          detail: user.phone,
          badge: user.role?.replaceAll('_', ' '),
          onTap: () => _addOrEdit(context, viewModel, roles, user),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, roles, user), destructive: false),
            (label: 'Reset password', icon: Icons.lock_reset_outlined, onTap: () => _resetPassword(context, viewModel, user), destructive: false),
            (label: 'Delete', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, user), destructive: true),
          ],
        );
      },
    );
  }
}
