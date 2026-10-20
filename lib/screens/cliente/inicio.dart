part of '../../main.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<Station> onRent;

  const HomePage({super.key, required this.onRent});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  GoogleMapController? mapController;
  final searchController = TextEditingController();
  LatLng center = diosPadreCenter;
  LatLng? searchedPoint;
  String? searchedName;
  bool searching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    FocusScope.of(context).unfocus();
    final query = searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de un lugar.')),
      );
      return;
    }

    setState(() => searching = true);

    final place = await MapSearchService.search(query);

    if (!mounted) return;
    setState(() => searching = false);

    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró "$query". Prueba agregando ciudad o estado.'),
        ),
      );
      return;
    }

    setState(() {
      center = place.point;
      searchedPoint = place.point;
      searchedName = place.displayName;
    });

    await mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place.point, 16.2),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mostrando: ${place.displayName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> currentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa la ubicación del dispositivo.')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se concedió permiso de ubicación.')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final point = LatLng(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() {
      searchedPoint = point;
      searchedName = 'Mi ubicación';
    });
    await mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(point, 16),
    );
  }

  void openStation(Station station) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.lime,
                size: 42,
              ),
              Text(
                station.name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('${station.bikes} bicicletas disponibles'),
              const SizedBox(height: 4),
              Text('${station.distanceKm.toStringAsFixed(1)} km de distancia'),
              const SizedBox(height: 20),
              AppButton(
                text: 'RENTAR EN ESTA ESTACIÓN',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onRent(station);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => search(),
            decoration: InputDecoration(
              hintText: 'Buscar lugar o ruta, ejemplo: Dios Padre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RealMap(
              center: center,
              searchedPoint: searchedPoint,
              searchedName: searchedName,
              onStationTap: openStation,
              onLocationPressed: currentLocation,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionCard(
                  icon: Icons.pedal_bike,
                  text: 'Rentar\nbicicleta',
                  onTap: () => widget.onRent(stations.first),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionCard(
                  icon: Icons.location_on_outlined,
                  text: 'Estaciones\ncercanas',
                  onTap: () => Navigator.push(
                    context,
                    fadeRoute(
                      StationsPage(onRent: widget.onRent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

