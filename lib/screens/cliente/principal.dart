part of '../../main.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  final Station? selectedStation;

  const MainPage({
    super.key,
    this.initialIndex = 0,
    this.selectedStation,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int index;
  Station? selectedStation;

  void goToHome() {
    if (!mounted) return;
    setState(() => index = 0);
  }

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    selectedStation = widget.selectedStation;
  }

  void openRent(Station station) {
    setState(() {
      selectedStation = station;
      index = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onRent: openRent),
      const RoutesPage(),
      BikeTypesContent(station: selectedStation ?? stations.first),
      ReservationLanding(
        key: ValueKey('reservation-$index'),
        station: selectedStation ?? stations.first,
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white70, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: AppColors.lime,
          unselectedItemColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 29,
          onTap: (value) {
            setState(() => index = value);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Rutas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pedal_bike_outlined),
              activeIcon: Icon(Icons.pedal_bike),
              label: 'Bicicletas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_calendar_outlined),
              activeIcon: Icon(Icons.edit_calendar),
              label: 'Reserva',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

