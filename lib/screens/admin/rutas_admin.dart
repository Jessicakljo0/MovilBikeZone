part of '../../main.dart';

class AdminRoutesPage extends StatelessWidget {
  const AdminRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminListScaffold(
      title: 'RECORRIDOS',
      stream: FirebaseFirestore.instance.collection('recorridos').snapshots(),
      itemBuilder: (doc) {
        final data = doc.data();

        return _AdminDataCard(
          icon: Icons.route_outlined,
          title: (data['ruta'] ?? data['bicicleta'] ?? data['bike'] ?? 'Recorrido')
              .toString(),
          lines: [
            if ((data['correoUsuario'] ?? '').toString().isNotEmpty)
              'Usuario: ${(data['correoUsuario']).toString()}',
            'Distancia: ${(data['distanciaKm'] ?? data['distancia'] ?? 0).toString()} km',
            'Tiempo: ${_formatAdminRideTime(data['tiempoSegundos'] ?? data['tiempo'] ?? 0)}',
            'Velocidad: ${(data['velocidadPromedioKmh'] ?? 0).toString()} km/h',
            'Estado: ${(data['estado'] ?? 'Finalizado').toString()}',
          ],
        );
      },
    );
  }
}

