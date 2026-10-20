part of '../../main.dart';

class NearbyStationsMapPage extends StatelessWidget {
  final List<Station> stations;

  const NearbyStationsMapPage({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    final center = stations.isEmpty ? diosPadreCenter : stations.first.point;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('MAPA DE ESTACIONES'),
      ),
      body: RealMap(
        center: center,
        customStations: stations,
      ),
    );
  }
}

