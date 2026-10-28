part of '../../main.dart';

class StationsPage extends StatelessWidget {
  final ValueChanged<Station> onRent;

  const StationsPage({super.key, required this.onRent});

  List<Station> get exampleStations => const [
    Station(name: 'Centro de Ixmiquilpan', point: centroIxmiquilpan, bikes: 14, distanceKm: 0.6),
    Station(name: 'El Nith', point: elNith, bikes: 9, distanceKm: 3.1),
    Station(name: 'El Fitzhi', point: elFitzhi, bikes: 11, distanceKm: 2.4),
    Station(name: 'La Otra Banda', point: laOtraBanda, bikes: 7, distanceKm: 1.8),
    Station(name: 'Dios Padre', point: diosPadreCenter, bikes: 12, distanceKm: 4.2),
    Station(name: 'Panales', point: panales, bikes: 8, distanceKm: 5.4),
    Station(name: 'Maguey Blanco', point: magueyBlanco, bikes: 10, distanceKm: 10.6),
    Station(name: 'Taxadho', point: taxadho, bikes: 6, distanceKm: 7.8),
    Station(name: 'Cantinela', point: cantinela, bikes: 5, distanceKm: 4.9),
    Station(name: 'Orizabita', point: orizabita, bikes: 9, distanceKm: 12.4),
    Station(name: 'Balneario Dios Padre', point: balnearioDiosPadre, bikes: 13, distanceKm: 3.5),
    Station(name: 'Balneario La Media Luna', point: balnearioMediaLuna, bikes: 15, distanceKm: 8.9),
    Station(name: 'UTVM', point: utvm, bikes: 16, distanceKm: 9.7),
  ];

  Future<void> openMap(BuildContext context, {Station? initialStation}) async {
    final selected = await Navigator.push<Station>(
      context,
      fadeRoute(NearbyStationsMapPage(
        stations: exampleStations,
        initialStation: initialStation,
      )),
    );
    if (!context.mounted || selected == null) return;

    // Cerrar primero la pantalla de estaciones: de lo contrario el usuario
    // solo ve el cambio de pestaña cuando pulsa Atrás.
    Navigator.pop(context);
    onRent(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text('Estaciones cercanas',
          style: TextStyle(fontSize: 25, fontStyle: FontStyle.italic)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Column(
          children: [
            const Text('Toca una estación para verla directamente en el mapa.',
              style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: exampleStations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final station = exampleStations[index];
                  return StationCard(
                    station: station,
                    onTap: () => openMap(context, initialStation: station),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              text: 'VER MAPA',
              width: 250,
              onPressed: () => openMap(context),
            ),
          ],
        ),
      ),
    );
  }
}
