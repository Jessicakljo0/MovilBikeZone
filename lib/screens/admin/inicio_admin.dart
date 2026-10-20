part of '../../main.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      fadeRoute(const WelcomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'BIKEZONE ADMIN',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.lime,
                size: 72,
              ),
              const SizedBox(height: 12),
              const Text(
                'Panel de administrador',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              _SimpleAdminButton(
                icon: Icons.people_outline,
                text: 'USUARIOS',
                onTap: () => Navigator.push(
                  context,
                  fadeRoute(const AdminUsersPage()),
                ),
              ),
              const SizedBox(height: 14),
              _SimpleAdminButton(
                icon: Icons.calendar_month_outlined,
                text: 'RESERVAS',
                onTap: () => Navigator.push(
                  context,
                  fadeRoute(const AdminReservationsPage()),
                ),
              ),
              const SizedBox(height: 14),
              _SimpleAdminButton(
                icon: Icons.route_outlined,
                text: 'RECORRIDOS',
                onTap: () => Navigator.push(
                  context,
                  fadeRoute(const AdminRoutesPage()),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: AppColors.red),
                  label: const Text(
                    'CERRAR SESIÓN',
                    style: TextStyle(color: AppColors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

