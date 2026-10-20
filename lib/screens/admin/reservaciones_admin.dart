part of '../../main.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminListScaffold(
      title: 'RESERVAS',
      stream: FirebaseFirestore.instance.collection('reservas').snapshots(),
      itemBuilder: (doc) {
        final data = doc.data();
        return _AdminDataCard(
          icon: Icons.calendar_month_outlined,
          title: (data['bike'] ?? data['bicicleta'] ?? 'Bicicleta').toString(),
          lines: [
            'Usuario: ${(data['correoUsuario'] ?? 'Sin correo').toString()}',
            'Estación: ${(data['station'] ?? data['estacion'] ?? '').toString()}',
            'Estado: ${(data['estado'] ?? 'Activa').toString()}',
          ],
        );
      },
    );
  }
}

String _formatAdminRideTime(dynamic value) {
  final seconds = value is int
      ? value
      : int.tryParse(value.toString()) ?? 0;

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}';
}

