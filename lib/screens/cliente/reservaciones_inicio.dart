part of '../../main.dart';

class ReservationLanding extends StatefulWidget {
  final Station station;
  const ReservationLanding({super.key, required this.station});
  @override
  State<ReservationLanding> createState() => _ReservationLandingState();
}

class _ReservationLandingState extends State<ReservationLanding> {
  late Future<List<ReservationRecord>> pending;
  @override
  void initState() { super.initState(); reload(); }
  void reload() { pending = UserStore.reservations(); }
  Future<void> refresh() async {
    setState(reload);
    try { await pending; } catch (_) {}
  }
  String imageForBike(String bike) {
    final lower = bike.toLowerCase();
    if (lower.contains('cannondale')) return AppAssets.bikeRed;
    if (lower.contains('trail')) return AppAssets.bikeBlue;
    if (lower.contains('eléctrica') || lower.contains('electrica')) return AppAssets.bikeGreen;
    return AppAssets.bikeYellow;
  }
  Future<void> cancel(ReservationRecord reservation) async {
    if (reservation.id == null) return;
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Cancelar reservación'),
      content: Text('¿Cancelar la reservación de ${reservation.bike}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Volver')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, cancelar')),
      ],
    ));
    if (yes != true || !mounted) return;
    try { await UserStore.cancelReservation(reservation.id!); await refresh(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cancelar: $e'))); }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReservationRecord>>(
      future: pending,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.lime));
        }
        if (snapshot.hasError) return Center(child: Text('Error cargando reservaciones: ${snapshot.error}'));
        final items = snapshot.data ?? <ReservationRecord>[];
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
            children: [
              const PageTitle('MIS RESERVAS'),
              const SizedBox(height: 12),
              Text('${items.length} reservaciones', textAlign: TextAlign.center),
              if (items.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aún no tienes reservaciones.'))),
              for (final reservation in items) Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.limeDark), borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(child: Image.asset(imageForBike(reservation.bike), height: 135, fit: BoxFit.contain)),
                    Text(reservation.bike, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _ReservationRow(label: 'Estado:', value: reservation.status),
                    _ReservationRow(label: 'Cantidad:', value: '${reservation.quantity}'),
                    _ReservationRow(label: 'Tiempo:', value: '${reservation.hours} hrs'),
                    _ReservationRow(label: 'Precio:', value: '\$${reservation.price} MXN'),
                    _ReservationRow(label: 'Estación:', value: reservation.station),
                    _ReservationRow(label: 'Fecha:', value: reservation.date),
                    const SizedBox(height: 16),
                    if (reservation.status == 'Activa' && reservation.id != null) ...[
                      AppButton(text: 'INICIAR RECORRIDO', onPressed: () async {
                        await Navigator.push(context, fadeRoute(ActiveRidePage(
                          bike: reservation.bike,
                          station: reservation.station,
                          reservationId: reservation.id!,
                        )));
                        if (mounted) await refresh();
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: () => cancel(reservation), child: const Text('CANCELAR RESERVA')),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
