part of '../../main.dart';

class ActiveRidePage extends StatefulWidget {
  final String bike;
  final String station;
  final String reservationId;

  const ActiveRidePage({
    super.key,
    required this.bike,
    required this.station,
    required this.reservationId,
  });

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  Timer? timer;
  StreamSubscription<Position>? positionSubscription;

  late final DateTime startedAt;

  int elapsedSeconds = 0;
  double distanceMeters = 0;
  Position? lastPosition;
  bool finishing = false;
  bool locationAvailable = false;

  // Modo de demostración para el emulador.
  // Déjalo en true para que avance distancia y velocidad sin moverte físicamente.
  static const bool demoMode = true;

  double get distanceKm => distanceMeters / 1000;

  double get averageSpeedKmh {
    if (elapsedSeconds <= 0) return 0;
    return distanceKm / (elapsedSeconds / 3600);
  }

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        elapsedSeconds++;

        // Simula aprox. 14.4 km/h en el emulador.
        if (demoMode) {
          distanceMeters += 4;
        }
      });
    });

    if (!demoMode) {
      _startLocationTracking();
    } else {
      locationAvailable = true;
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      if (mounted) {
        setState(() => locationAvailable = true);
      }

      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        final previous = lastPosition;

        if (previous != null) {
          final meters = Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );

          if (meters >= 1 && meters <= 250) {
            if (mounted) {
              setState(() => distanceMeters += meters);
            } else {
              distanceMeters += meters;
            }
          }
        }

        lastPosition = position;
      });
    } catch (_) {
      // El recorrido sigue funcionando aunque no haya GPS.
    }
  }

  Future<void> finishRide() async {
    if (finishing) return;

    setState(() => finishing = true);

    timer?.cancel();
    await positionSubscription?.cancel();

    try {
      await UserStore.saveRide(
        reservationId: widget.reservationId,
        bike: widget.bike,
        station: widget.station,
        startedAt: startedAt,
        elapsedSeconds: elapsedSeconds,
        distanceKm: distanceKm,
        averageSpeedKmh: averageSpeedKmh,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.card,
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.lime,
            size: 48,
          ),
          title: const Text('Recorrido guardado'),
          content: Text(
            'Tiempo: $formattedTime\n'
            'Distancia: ${distanceKm.toStringAsFixed(2)} km\n'
            'Velocidad promedio: ${averageSpeedKmh.toStringAsFixed(1)} km/h',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: AppColors.lime),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => finishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el recorrido: $e'),
          backgroundColor: AppColors.red,
        ),
      );

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;

        setState(() {
          elapsedSeconds++;
          if (demoMode) {
            distanceMeters += 4;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text('RECORRIDO ACTIVO'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 25),
              const Icon(
                Icons.directions_bike,
                color: AppColors.lime,
                size: 92,
              ),
              const SizedBox(height: 18),
              Text(
                widget.bike,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.station,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 35),
              Text(
                formattedTime,
                style: const TextStyle(
                  color: AppColors.lime,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              _RideMetric(
                label: 'Distancia',
                value: '${distanceKm.toStringAsFixed(2)} km',
              ),
              const SizedBox(height: 14),
              _RideMetric(
                label: 'Velocidad promedio',
                value: '${averageSpeedKmh.toStringAsFixed(1)} km/h',
              ),
              const SizedBox(height: 14),
              _RideMetric(
                label: 'Modo',
                value: demoMode
                    ? 'Simulación'
                    : (locationAvailable ? 'GPS activo' : 'GPS no disponible'),
              ),
              const Spacer(),
              AppButton(
                text: finishing ? 'GUARDANDO...' : 'FINALIZAR RECORRIDO',
                onPressed: finishing ? null : finishRide,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

