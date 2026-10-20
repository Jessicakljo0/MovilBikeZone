part of '../../main.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminListScaffold(
      title: 'USUARIOS',
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      itemBuilder: (doc) {
        final data = doc.data();
        return _AdminDataCard(
          icon: Icons.person_outline,
          title: (data['nombre'] ?? 'Usuario').toString(),
          lines: [
            'Correo: ${(data['correo'] ?? 'Sin correo').toString()}',
          ],
        );
      },
    );
  }
}

