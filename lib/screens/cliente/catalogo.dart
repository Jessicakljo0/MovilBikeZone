part of '../../main.dart';

class CatalogPage extends StatelessWidget {
  final String type;
  final Station station;

  const CatalogPage({
    super.key,
    required this.type,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    const bikes = <BikeOption>[
      BikeOption('Bicicleta Alubike MTB', AppAssets.bikeYellow, true),
      BikeOption('Bicicleta 29 Cannondale', AppAssets.bikeRed, true),
      BikeOption('Bicicleta Trail Cube', AppAssets.bikeBlue, true),
      BikeOption('Bicicleta Eléctrica Verde', AppAssets.bikeGreen, true),
      BikeOption('Bicicleta Alubike Pro', AppAssets.bikeYellow, true),
      BikeOption('Bicicleta Cannondale Sport', AppAssets.bikeRed, true),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'CATÁLOGO',
          style: TextStyle(
            fontSize: 29,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: bikes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final bike = bikes[index];
          return BikeCard(
            bike: bike,
            onTap: bike.available
                ? () => Navigator.push(
                      context,
                      fadeRoute(
                        ReservationPage(
                          bike: bike,
                          station: station,
                          type: type,
                        ),
                      ),
                    )
                : null,
          );
        },
      ),
    );
  }
}

