part of '../../main.dart';

class NearbyStationsMapPage extends StatefulWidget {
  final List<Station> stations;
  final Station? initialStation;

  const NearbyStationsMapPage({
    super.key,
    required this.stations,
    this.initialStation,
  });

  @override
  State<NearbyStationsMapPage> createState() => _NearbyStationsMapPageState();
}

class _NearbyStationsMapPageState extends State<NearbyStationsMapPage> {
  GoogleMapController? _controller;
  Station? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStation;
  }

  Future<void> _select(Station station) async {
    setState(() => _selected = station);
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(station.point, 16.3),
    );
  }

  @override
  void dispose() {
    // RealMap owns the GoogleMap widget; it will dispose its map internally.
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final initialCenter = widget.initialStation?.point ??
        (widget.stations.isEmpty ? diosPadreCenter : widget.stations.first.point);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('MAPA DE ESTACIONES'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RealMap(
              center: initialCenter,
              customStations: widget.stations,
              onMapCreated: (controller) => _controller = controller,
              onStationTap: _select,
            ),
          ),
          if (selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.lime),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selected.name, style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 6),
                    Text('${selected.bikes} bicicletas (inventario de demostración)',
                      style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'RENTAR EN ESTA ESTACIÓN',
                      onPressed: () => Navigator.pop(context, selected),
                    ),
                  ],
                ),
              ),
            ),
          if (selected == null)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Toca un marcador verde para seleccionar una estación.',
                  textAlign: TextAlign.center),
              )),
            ),
        ],
      ),
    );
  }
}
