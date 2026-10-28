part of '../../main.dart';

class ReservationPage extends StatefulWidget {
  final BikeOption bike;
  final Station station;
  final String type;

  const ReservationPage({
    super.key,
    required this.bike,
    required this.station,
    required this.type,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  int hours = 2;
  int quantity = 1;
  DateTime selectedDate = DateTime.now();
  bool saving = false;
  late Station selectedStation;

  int get hourlyRate => widget.type == 'Eléctrica' ? 45 : 25;
  int get price => hours * hourlyRate * quantity;
int get maxBikes => DemoBikeInventory.availableFor(
  station: selectedStation,
  model: widget.bike.name,
);
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 180)), initialDate: selectedDate.isBefore(now) ? now : selectedDate);
    if (picked != null && mounted) setState(() => selectedDate = picked);
  }

  @override
  void initState() {
    super.initState();
    selectedStation = widget.station;
  }

  List<Station> _reservationStations() {
    final all = <Station>[
      selectedStation,
      ...stations,
      const Station(name: 'Centro de Ixmiquilpan', point: centroIxmiquilpan, bikes: 14, distanceKm: 0.6),
      const Station(name: 'El Nith', point: elNith, bikes: 9, distanceKm: 3.1),
      const Station(name: 'El Fitzhi', point: elFitzhi, bikes: 11, distanceKm: 2.4),
      const Station(name: 'La Otra Banda', point: laOtraBanda, bikes: 7, distanceKm: 1.8),
      const Station(name: 'Dios Padre', point: diosPadreCenter, bikes: 12, distanceKm: 4.2),
      const Station(name: 'Panales', point: panales, bikes: 8, distanceKm: 5.4),
      const Station(name: 'Maguey Blanco', point: magueyBlanco, bikes: 10, distanceKm: 10.6),
      const Station(name: 'Taxadho', point: taxadho, bikes: 6, distanceKm: 7.8),
      const Station(name: 'Cantinela', point: cantinela, bikes: 5, distanceKm: 4.9),
      const Station(name: 'Orizabita', point: orizabita, bikes: 9, distanceKm: 12.4),
      const Station(name: 'Balneario Dios Padre', point: balnearioDiosPadre, bikes: 13, distanceKm: 3.5),
      const Station(name: 'Balneario La Media Luna', point: balnearioMediaLuna, bikes: 15, distanceKm: 8.9),
      const Station(name: 'UTVM', point: utvm, bikes: 16, distanceKm: 9.7),
    ];

    final unique = <String, Station>{};
    for (final station in all) {
      unique[station.name] = station;
    }
    return unique.values.toList();
  }

  Future<void> confirm() async {
    if (saving) return;
   if (maxBikes <= 0 || quantity > maxBikes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad no disponible en esta estación.')));
      return;
    }
    final date = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Confirma tu reservación'),
      content: Text('${widget.bike.name}\n$quantity bicicleta(s)\n$hours hora(s)\n$date\n${selectedStation.name}\n\$$price MXN'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Volver')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar')),
      ],
    ));
    if (ok != true || !mounted) return;
    setState(() => saving = true);
    try {
      await UserStore.saveReservation(ReservationRecord(
        bike: widget.bike.name, station: selectedStation.name,
        hours: hours, price: price, date: date, quantity: quantity,
      ));
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: const Text('Reserva confirmada'),
        content: Text('${widget.bike.name}\n$quantity bicicleta(s)\n$date'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Aceptar'))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo reservar: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'RESERVA',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 5, 24, 30),
          children: [
            SizedBox(
              height: 260,
              child: Image.asset(
                widget.bike.image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.bike.name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              widget.type,
              style: const TextStyle(
                fontSize: 21,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tiempo:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 165,
                  child: DropdownButtonFormField<int>(
                    value: hours,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lime,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lime,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: List.generate(24, (index) {
                      final value = index + 1;
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          value == 1 ? '1 hr' : '$value hrs',
                          style: const TextStyle(fontSize: 19),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => hours = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Text(
                  'Precio:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    '\$$price MXN',
                    key: ValueKey(price),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estación de retiro:',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    value: selectedStation.name,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.lime),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lime,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: _reservationStations()
                        .map(
                          (station) => DropdownMenuItem<String>(
                            value: station.name,
                            child: Text(
                              station.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final station = _reservationStations().firstWhere(
                        (item) => item.name == value,
                      );
                      setState(() {selectedStation = station; if (quantity > maxBikes) {quantity = maxBikes > 0 ? maxBikes : 1;}
});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListTile(
              title: const Text('Fecha de reservación'),
              subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              trailing: const Icon(Icons.calendar_month, color: AppColors.lime),
              onTap: pickDate,
            ),
            
Row(
  children: [
    const Expanded(
      child: Text('Cantidad de bicicletas:'),
    ),
    IconButton(
      icon: const Icon(Icons.remove_circle_outline),
      onPressed: quantity > 1
          ? () => setState(() => quantity--)
          : null,
    ),
    Text(
      '$quantity',
      style: const TextStyle(fontSize: 20),
    ),
    IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: quantity < maxBikes
          ? () => setState(() => quantity++)
          : null,
    ),
  ],
),

            const SizedBox(height: 31),
            Center(
              child: AppButton(
                text: 'CONFIRMAR RESERVA',
                width: 255,
                onPressed: saving ? null : confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

