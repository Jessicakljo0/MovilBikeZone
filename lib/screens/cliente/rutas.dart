part of '../../main.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  GoogleMapController? mapController;
  final originController = TextEditingController();
  final destinationController = TextEditingController();

  SearchPlace? origin;
  SearchPlace? destination;
  List<LatLng> routePoints = const [];
  double distanceKm = 0;
  double durationMinutes = 0;
  bool loading = false;
  bool searchingOrigin = false;
  bool searchingDestination = false;
  bool routeReady = false;

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<SearchPlace?> _pickPlace(String query, String title) async {
    final results = await MapSearchService.searchMany(query);
    if (!mounted) return null;
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró "$query".')),
      );
      return null;
    }
    if (results.length == 1) return results.first;

    return showModalBottomSheet<SearchPlace>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .58,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final place = results[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.lime,
                      ),
                      title: Text(
                        place.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(sheetContext, place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> searchOrigin() async {
    FocusScope.of(context).unfocus();
    final query = originController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el lugar de origen.')),
      );
      return;
    }
    setState(() => searchingOrigin = true);
    final place = await _pickPlace(query, 'Selecciona el origen');
    if (!mounted) return;
    setState(() {
      searchingOrigin = false;
      if (place != null) {
        origin = place;
        originController.text = place.displayName;
        routeReady = false;
        routePoints = const [];
      }
    });
    if (place != null) {
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(place.point, 16),
      );
    }
  }

  Future<void> searchDestination() async {
    FocusScope.of(context).unfocus();
    final query = destinationController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el lugar de destino.')),
      );
      return;
    }
    setState(() => searchingDestination = true);
    final place = await _pickPlace(query, 'Selecciona el destino');
    if (!mounted) return;
    setState(() {
      searchingDestination = false;
      if (place != null) {
        destination = place;
        destinationController.text = place.displayName;
        routeReady = false;
        routePoints = const [];
      }
    });
    if (place != null) {
      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(place.point, 16),
      );
    }
  }

  Future<void> calculateRoute() async {
    FocusScope.of(context).unfocus();
    if (origin == null || originController.text.trim() != origin!.displayName) {
      await searchOrigin();
    }
    if (!mounted) return;
    if (destination == null ||
        destinationController.text.trim() != destination!.displayName) {
      await searchDestination();
    }
    if (!mounted) return;

    final from = origin;
    final to = destination;
    if (from == null || to == null) return;

    if (from.point.latitude == to.point.latitude &&
        from.point.longitude == to.point.longitude) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El origen y destino deben ser diferentes.')),
      );
      return;
    }

    setState(() {
      loading = true;
      routeReady = false;
    });

    final result = await RouteService.getRoute(
      origin: from.point,
      destination: to.point,
    );
    if (!mounted) return;

    setState(() {
      loading = false;
      routeReady = true;
      routePoints = result.points;
      distanceKm = result.distanceKm;
      durationMinutes = result.durationMinutes;
    });

    if (routePoints.isNotEmpty && mapController != null) {
      double minLat = routePoints.first.latitude;
      double maxLat = routePoints.first.latitude;
      double minLng = routePoints.first.longitude;
      double maxLng = routePoints.first.longitude;
      for (final point in routePoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          58,
        ),
      );
    }
  }

  void swapPlaces() {
    final oldOrigin = origin;
    final oldText = originController.text;
    setState(() {
      origin = destination;
      destination = oldOrigin;
      originController.text = destinationController.text;
      destinationController.text = oldText;
      routeReady = false;
      routePoints = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        children: [
          const PageTitle('RUTAS'),
          const SizedBox(height: 10),
          Expanded(
            child: RealMap(
              center: origin?.point ?? centroIxmiquilpan,
              routeOriginPoint: origin?.point,
              routeOriginName: origin?.displayName,
              routePoints: routePoints,
              searchedPoint: destination?.point,
              searchedName: destination?.displayName,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: originController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchOrigin(),
            decoration: InputDecoration(
              labelText: 'Origen',
              hintText: 'Ej. Barrio de Jesús',
              prefixIcon: const Icon(Icons.trip_origin),
              suffixIcon: searchingOrigin
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: searchOrigin,
                      icon: const Icon(Icons.search),
                    ),
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: destinationController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchDestination(),
            decoration: InputDecoration(
              labelText: 'Destino',
              hintText: 'Ej. El Barrido',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: searchingDestination
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: searchDestination,
                      icon: const Icon(Icons.search),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (routeReady && origin != null && destination != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.limeDark),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bike, color: AppColors.lime),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${origin!.displayName} → ${destination!.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: loading ? 'CALCULANDO...' : 'MOSTRAR RUTA',
                  onPressed: loading ? null : calculateRoute,
                ),
              ),
              const SizedBox(width: 9),
              IconButton(
                tooltip: 'Intercambiar origen y destino',
                onPressed: loading ? null : swapPlaces,
                icon: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.lime,
                  size: 31,
                ),
              ),
            ],
          ),
          if (routeReady) ...[
            const SizedBox(height: 6),
            Text(
              'Tiempo estimado en bicicleta: ${durationMinutes.ceil()} min (aprox.)',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

