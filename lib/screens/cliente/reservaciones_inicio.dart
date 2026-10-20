part of '../../main.dart';

class ReservationLanding extends StatelessWidget {
  final Station station;

  const ReservationLanding({super.key, required this.station});

  String imageForBike(String bike) {
    final lower = bike.toLowerCase();
    if (lower.contains('cannondale')) return AppAssets.bikeRed;
    if (lower.contains('trail')) return AppAssets.bikeBlue;
    if (lower.contains('eléctrica') || lower.contains('electrica')) {
      return AppAssets.bikeGreen;
    }
    return AppAssets.bikeYellow;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReservationRecord>>(
      future: UserStore.reservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          );
        }

        final items = snapshot.data ?? const <ReservationRecord>[];

        if (items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(26, 60, 26, 25),
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 80,
                color: AppColors.lime,
              ),
              const SizedBox(height: 20),
              const Text(
                'Aún no tienes una reserva',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Selecciona una bicicleta desde la sección Bicicletas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          );
        }

        final reservation = items.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
          children: [
            const PageTitle('MI RESERVA'),
            const SizedBox(height: 12),
            SizedBox(
              height: 255,
              child: Image.asset(
                imageForBike(reservation.bike),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reservation.bike,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.lime),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ReservationRow(
                    label: 'Tiempo:',
                    value: '${reservation.hours} hrs',
                  ),
                  const SizedBox(height: 15),
                  _ReservationRow(
                    label: 'Precio:',
                    value: '\$${reservation.price} MXN',
                  ),
                  const SizedBox(height: 15),
                  _ReservationRow(
                    label: 'Estación:',
                    value: reservation.station,
                  ),
                  const SizedBox(height: 15),
                  _ReservationRow(
                    label: 'Fecha:',
                    value: reservation.date,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'INICIAR RECORRIDO',
              onPressed: () async {
                await Navigator.push(
                  context,
                  fadeRoute(
                    ActiveRidePage(
                      bike: reservation.bike,
                      station: reservation.station,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

