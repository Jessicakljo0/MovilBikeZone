part of '../../main.dart';

class BikeTypesContent extends StatelessWidget {
  final Station station;

  const BikeTypesContent({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        const PageTitle('TIPOS DE BICICLETAS'),
        const SizedBox(height: 8),
        Text(
          'Estación: ${station.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        BikeTypeCard(
          title: 'Montaña',
          image: AppAssets.mountain,
          onTap: () => openCatalog(context, 'Montaña'),
        ),
        const SizedBox(height: 17),
        BikeTypeCard(
          title: 'Urbana',
          image: AppAssets.urban,
          onTap: () => openCatalog(context, 'Urbana'),
        ),
        const SizedBox(height: 17),
        BikeTypeCard(
          title: 'Eléctrica',
          image: AppAssets.electric,
          onTap: () => openCatalog(context, 'Eléctrica'),
        ),
      ],
    );
  }

  void openCatalog(BuildContext context, String type) {
    Navigator.push(
      context,
      fadeRoute(CatalogPage(type: type, station: station)),
    );
  }
}

