part of '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  Map<String, String> profile = const {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loadedProfile = await UserStore.profile();
    if (!mounted) return;
    setState(() => profile = loadedProfile);
  }

  void editProfile() {
    final name = TextEditingController(text: profile['name']);
    final phone = TextEditingController(text: profile['phone']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await UserStore.updateProfile(
                  name: name.text,
                  phone: phone.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                load();
             } on FormatException catch (e) {
  if (!dialogContext.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message),
      backgroundColor: AppColors.red,
    ),
  );
} catch (e) {
  if (!dialogContext.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No se pudo actualizar el perfil. Intenta nuevamente.'),
      backgroundColor: AppColors.red,
    ),
  );
}
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.lime),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Si algún proveedor ya estaba cerrado, seguimos con el cierre local.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      fadeRoute(const WelcomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 26),
      children: [
        const Text(
          'Perfil',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: CircleAvatar(
            radius: 62,
            backgroundColor: Color(0xFFE8E8E8),
            child: Icon(
              Icons.person,
              size: 82,
              color: Color(0xFF654B70),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          profile['name'] ?? 'Cargando...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          profile['phone'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 35),
        ProfileAction(
          icon: Icons.person_outline,
          text: 'Editar perfil',
          onTap: editProfile,
        ),
        const SizedBox(height: 13),
        ProfileAction(
          icon: Icons.logout,
          text: 'Salir',
          onTap: logout,
        ),
        const SizedBox(height: 48),
        Center(
          child: SizedBox(
            width: 180,
            height: 48,
            child: ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3945),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ),
      ],
    );
  }
}

