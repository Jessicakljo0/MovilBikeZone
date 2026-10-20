import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'firebase_options.dart';

part 'screens/auth/bienvenida.dart';
part 'screens/auth/registro.dart';
part 'screens/auth/login.dart';
part 'screens/cliente/principal.dart';
part 'screens/cliente/inicio.dart';
part 'screens/cliente/estaciones.dart';
part 'screens/cliente/mapa_estaciones_cercanas.dart';
part 'screens/cliente/rutas.dart';
part 'screens/cliente/tipos_bicicletas.dart';
part 'screens/cliente/catalogo.dart';
part 'screens/cliente/reservaciones_inicio.dart';
part 'screens/cliente/recorrido_activo.dart';
part 'screens/cliente/reservar.dart';
part 'screens/cliente/perfil.dart';
part 'screens/admin/inicio_admin.dart';
part 'screens/admin/usuarios_admin.dart';
part 'screens/admin/reservaciones_admin.dart';
part 'screens/admin/rutas_admin.dart';


final GlobalKey<ScaffoldMessengerState> bikeZoneMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // google_sign_in 7.x debe inicializarse una sola vez antes de authenticate().
  await GoogleSignIn.instance.initialize();

  runApp(const BikeZoneApp());
}

 
class BikeZoneApp extends StatelessWidget {
  const BikeZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: bikeZoneMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'BikeZone',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.lime,
          secondary: AppColors.lime,
          surface: AppColors.card,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          labelStyle: const TextStyle(color: AppColors.muted),
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIconColor: AppColors.lime,
          suffixIconColor: AppColors.lime,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.limeDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.lime, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.red),
          ),
        ),
      ),
      home: const WelcomePage(),
    );
  }
}

class AppColors {
  static const background = Color(0xFF030303);
  static const card = Color(0xFF0D0D0D);
  static const lime = Color(0xFFB6FF00);
  static const limeDark = Color(0xFF6B9800);
  static const muted = Color(0xFFBEBEBE);
  static const red = Color(0xFFFF4A55);
}

class AppAssets {
  static const logo = 'assets/images/logo.png';
  static const welcomeBike = 'assets/images/bienvenida.png';
  static const mountain = 'assets/images/montana.png';
  static const urban = 'assets/images/urbana.png';
  static const electric = 'assets/images/electrica.png';
  static const bikeYellow = 'assets/images/catalogo_amarilla.png';
  static const bikeRed = 'assets/images/catalogo_roja.png';
  static const bikeBlue = 'assets/images/catalogo_azul.png';
  static const bikeGreen = 'assets/images/catalogo_verde.png';
}

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, animation, __) => FadeTransition(
      opacity: animation,
      child: page,
    ),
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

class UserStore {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'No se pudo crear el usuario.',
      );
    }

    await _db.collection('usuarios').doc(user.uid).set({
      'nombre': name.trim(),
      'correo': email.trim().toLowerCase(),
      'telefono': phone.trim(),
      'rol': 'usuario',
      'proveedor': 'correo',
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    await _auth.signOut();
  }

  static Future<bool> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user != null;
  }

  static Future<Map<String, String>> profile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {
        'name': 'Usuario BikeZone',
        'email': '',
        'phone': '',
      };
    }

    final doc = await _db.collection('usuarios').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    return {
      'name': (data['nombre'] ?? user.displayName ?? 'Usuario BikeZone').toString(),
      'email': (data['correo'] ?? user.email ?? '').toString(),
      'phone': (data['telefono'] ?? '').toString(),
    };
  }

  static Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No hay un usuario autenticado.',
      );
    }

    await _db.collection('usuarios').doc(user.uid).set({
      'nombre': name.trim(),
      'telefono': phone.trim(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveReservation(ReservationRecord record) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Debes iniciar sesión para reservar.',
      );
    }

    await _db.collection('reservas').add({
      'uidUsuario': user.uid,
      'correoUsuario': user.email ?? '',
      ...record.toJson(),
      'estado': 'Activa',
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveRide({
    required String bike,
    required String station,
    required DateTime startedAt,
    required int elapsedSeconds,
    required double distanceKm,
    required double averageSpeedKmh,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Debes iniciar sesión para guardar un recorrido.',
      );
    }

    await _db.collection('recorridos').add({
      'uidUsuario': user.uid,
      'correoUsuario': user.email ?? '',
      'bicicleta': bike,
      'estacion': station,
      'fechaInicio': Timestamp.fromDate(startedAt),
      'fechaFin': FieldValue.serverTimestamp(),
      'tiempoSegundos': elapsedSeconds,
      'distanciaKm': double.parse(distanceKm.toStringAsFixed(3)),
      'velocidadPromedioKmh':
          double.parse(averageSpeedKmh.toStringAsFixed(2)),
      'estado': 'Finalizado',
    });
  }

  static Future<List<ReservationRecord>> reservations() async {
    final user = _auth.currentUser;
    if (user == null) return <ReservationRecord>[];

    final snapshot = await _db
        .collection('reservas')
        .where('uidUsuario', isEqualTo: user.uid)
        .get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aTs = a.data()['fechaCreacion'] as Timestamp?;
        final bTs = b.data()['fechaCreacion'] as Timestamp?;
        return (bTs?.millisecondsSinceEpoch ?? 0)
            .compareTo(aTs?.millisecondsSinceEpoch ?? 0);
      });

    return docs
        .map((doc) => ReservationRecord.fromJson(doc.data()))
        .toList();
  }

  static Future<String> role() async {
    final user = _auth.currentUser;

    if (user == null) {
      debugPrint('ROLE DEBUG: no hay usuario autenticado');
      return 'usuario';
    }

    debugPrint('ROLE DEBUG UID: ${user.uid}');
    debugPrint('ROLE DEBUG EMAIL: ${user.email}');

    final doc = await _db
        .collection('usuarios')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    if (!doc.exists) {
      debugPrint('ROLE DEBUG: no existe documento para UID ${user.uid}');
      return 'usuario';
    }

    final data = doc.data();
    final role = (data?['rol'] ?? 'usuario')
        .toString()
        .trim()
        .toLowerCase();

    debugPrint('ROLE DEBUG FIRESTORE: $role');

    return role;
  }

  static Future<void> ensureSocialUser({
    required User user,
    required String provider,
  }) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'nombre': user.displayName ?? 'Usuario BikeZone',
        'correo': user.email ?? '',
        'telefono': '',
        'rol': 'usuario',
        'proveedor': provider,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    }
  }
}

class ReservationRecord {
  final String bike;
  final String station;
  final int hours;
  final int price;
  final String date;

  const ReservationRecord({
    required this.bike,
    required this.station,
    required this.hours,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'bike': bike,
        'station': station,
        'hours': hours,
        'price': price,
        'date': date,
      };

  factory ReservationRecord.fromJson(Map<String, dynamic> json) {
    return ReservationRecord(
      bike: json['bike'] as String? ?? '',
      station: json['station'] as String? ?? '',
      hours: json['hours'] as int? ?? 1,
      price: json['price'] as int? ?? 25,
      date: json['date'] as String? ?? '',
    );
  }
}

class Station {
  final String name;
  final LatLng point;
  final int bikes;
  final double distanceKm;

  const Station({
    required this.name,
    required this.point,
    required this.bikes,
    required this.distanceKm,
  });

  @override
  bool operator ==(Object other) {
    return other is Station && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

// Coordenadas base compartidas por Inicio, Estaciones y Rutas.
// Así el mismo lugar siempre apunta al mismo punto en Google Maps.
const centroIxmiquilpan = LatLng(20.4819, -99.2181);
const elNith = LatLng(20.48981, -99.19102);
const elFitzhi = LatLng(20.46730, -99.21018);
const laOtraBanda = LatLng(20.4868, -99.2297);
const diosPadreCenter = LatLng(20.4765, -99.2015);
const panales = LatLng(20.5178, -99.1977);
const magueyBlanco = LatLng(20.5633, -99.1688);
const taxadho = LatLng(20.4518, -99.1779);
const cantinela = LatLng(20.4564, -99.2168);
const orizabita = LatLng(20.5884, -99.2085);
const balnearioDiosPadre = LatLng(20.4765, -99.2015);
const balnearioMediaLuna = LatLng(20.4372, -99.1907);
const utvm = LatLng(20.5454, -99.1762);

const stations = <Station>[
  Station(
    name: 'Centro de Ixmiquilpan',
    point: centroIxmiquilpan,
    bikes: 14,
    distanceKm: 0.6,
  ),
  Station(
    name: 'El Nith',
    point: elNith,
    bikes: 9,
    distanceKm: 3.1,
  ),
  Station(
    name: 'El Fitzhi',
    point: elFitzhi,
    bikes: 11,
    distanceKm: 2.4,
  ),
  Station(
    name: 'Dios Padre',
    point: diosPadreCenter,
    bikes: 12,
    distanceKm: 4.2,
  ),
];

class SearchPlace {
  final String displayName;
  final LatLng point;

  const SearchPlace(this.displayName, this.point);
}

class MapSearchService {
  static const Map<String, SearchPlace> ixmiquilpanPlaces = {
    'centro de ixmiquilpan': SearchPlace(
      'Centro de Ixmiquilpan, Hidalgo',
      centroIxmiquilpan,
    ),
    'ixmiquilpan centro': SearchPlace(
      'Centro de Ixmiquilpan, Hidalgo',
      centroIxmiquilpan,
    ),
    'el nith': SearchPlace(
      'El Nith, Ixmiquilpan, Hidalgo',
      elNith,
    ),
    'nith': SearchPlace(
      'El Nith, Ixmiquilpan, Hidalgo',
      elNith,
    ),
    'el fitzhi': SearchPlace(
      'El Fitzhi, Ixmiquilpan, Hidalgo',
      elFitzhi,
    ),
    'el fithzi': SearchPlace(
      'El Fitzhi, Ixmiquilpan, Hidalgo',
      elFitzhi,
    ),
    'fitzhi': SearchPlace(
      'El Fitzhi, Ixmiquilpan, Hidalgo',
      elFitzhi,
    ),
    'fithzi': SearchPlace(
      'El Fitzhi, Ixmiquilpan, Hidalgo',
      elFitzhi,
    ),
    'la otra banda': SearchPlace(
      'La Otra Banda, Ixmiquilpan, Hidalgo',
      laOtraBanda,
    ),
    'otra banda': SearchPlace(
      'La Otra Banda, Ixmiquilpan, Hidalgo',
      laOtraBanda,
    ),
    'dios padre': SearchPlace(
      'Dios Padre, Ixmiquilpan, Hidalgo',
      diosPadreCenter,
    ),
    'panales': SearchPlace(
      'Panales, Ixmiquilpan, Hidalgo',
      panales,
    ),
    'maguey blanco': SearchPlace(
      'Maguey Blanco, Ixmiquilpan, Hidalgo',
      magueyBlanco,
    ),
    'taxadho': SearchPlace(
      'Taxadho, Ixmiquilpan, Hidalgo',
      taxadho,
    ),
    'cantinela': SearchPlace(
      'Cantinela, Ixmiquilpan, Hidalgo',
      cantinela,
    ),
    'orizabita': SearchPlace(
      'Orizabita, Ixmiquilpan, Hidalgo',
      orizabita,
    ),
    'balneario dios padre': SearchPlace(
      'Balneario Dios Padre, Ixmiquilpan, Hidalgo',
      balnearioDiosPadre,
    ),
    'balneario la media luna': SearchPlace(
      'Balneario La Media Luna, Ixmiquilpan, Hidalgo',
      balnearioMediaLuna,
    ),
    'la media luna': SearchPlace(
      'Balneario La Media Luna, Ixmiquilpan, Hidalgo',
      balnearioMediaLuna,
    ),
    'utvm': SearchPlace(
      'Universidad Tecnológica del Valle del Mezquital',
      utvm,
    ),
    'universidad tecnológica del valle del mezquital': SearchPlace(
      'Universidad Tecnológica del Valle del Mezquital',
      utvm,
    ),
    'universidad tecnologica del valle del mezquital': SearchPlace(
      'Universidad Tecnológica del Valle del Mezquital',
      utvm,
    ),
  };

  static Future<List<SearchPlace>> searchMany(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return <SearchPlace>[];

    final lower = normalized.toLowerCase();
    final results = <SearchPlace>[];

    for (final entry in ixmiquilpanPlaces.entries) {
      final place = entry.value;
      if (entry.key.contains(lower) ||
          lower.contains(entry.key) ||
          place.displayName.toLowerCase().contains(lower)) {
        if (!results.any((item) => item.displayName == place.displayName)) {
          results.add(place);
        }
      }
    }

    final queries = <String>[
      '$normalized, Ixmiquilpan, Hidalgo, México',
      '$normalized, Hidalgo, México',
      '$normalized, México',
      normalized,
    ];

    for (final item in queries) {
      try {
        final uri = Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'q': item,
            'format': 'jsonv2',
            'limit': '6',
            'countrycodes': 'mx',
            'addressdetails': '1',
          },
        );

        final response = await http
            .get(
              uri,
              headers: const {
                'User-Agent': 'BikeZone university Flutter application',
                'Accept-Language': 'es-MX,es',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as List<dynamic>;
        for (final raw in data) {
          final result = raw as Map<String, dynamic>;
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lon = double.tryParse(result['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final displayName = result['display_name']?.toString() ?? normalized;
          if (!results.any((place) => place.displayName == displayName)) {
            results.add(SearchPlace(displayName, LatLng(lat, lon)));
          }
        }
        if (results.length >= 6) break;
      } catch (_) {}
    }

    return results.take(6).toList();
  }

  static Future<SearchPlace?> search(String query) async {
    final results = await searchMany(query);
    return results.isEmpty ? null : results.first;
  }
}


class NearbyStationService {
  static List<Station> fallbackStations({
    double lat = 20.7483,
    double lon = -99.2187,
  }) {
    const names = [
      'Estación Centro',
      'Estación Universidad',
      'Estación Parque',
      'Estación Principal',
      'Estación Norte',
    ];

    return List.generate(5, (index) {
      final offset = (index + 1) * 0.0028;
      return Station(
        name: names[index],
        point: LatLng(
          lat + (index.isEven ? offset : -offset),
          lon + (index % 3 == 0 ? offset : -offset / 2),
        ),
        bikes: 4 + ((index * 4) % 13),
        distanceKm: 0.6 + (index * 0.8),
      );
    });
  }

  static Future<List<Station>> loadNearby() async {
    double lat = diosPadreCenter.latitude;
    double lon = diosPadreCenter.longitude;

    try {
      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2));

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5));
      }

      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2));

      if (enabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 6));

        lat = position.latitude;
        lon = position.longitude;
      }
    } catch (_) {}

    final query = '''
[out:json][timeout:8];
(
  node["amenity"="bicycle_rental"](around:10000,$lat,$lon);
  way["amenity"="bicycle_rental"](around:10000,$lat,$lon);
  relation["amenity"="bicycle_rental"](around:10000,$lat,$lon);
);
out center 12;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'BikeZone university Flutter application',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = body['elements'] as List<dynamic>? ?? [];
        final result = <Station>[];

        for (var i = 0; i < elements.length; i++) {
          final element = elements[i] as Map<String, dynamic>;
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final center = element['center'] as Map<String, dynamic>?;
          final itemLat = (element['lat'] ?? center?['lat']) as num?;
          final itemLon = (element['lon'] ?? center?['lon']) as num?;
          if (itemLat == null || itemLon == null) continue;

          final name = (tags['name'] as String?)?.trim();
          result.add(
            Station(
              name: name?.isNotEmpty == true
                  ? name!
                  : 'Estación de bicicletas ${i + 1}',
              point: LatLng(itemLat.toDouble(), itemLon.toDouble()),
              bikes: 3 + ((i * 5) % 14),
              distanceKm: Geolocator.distanceBetween(
                    lat,
                    lon,
                    itemLat.toDouble(),
                    itemLon.toDouble(),
                  ) /
                  1000,
            ),
          );
        }

        if (result.isNotEmpty) {
          result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          return result.take(8).toList();
        }
      }
    } catch (_) {}

    return fallbackStations(lat: lat, lon: lon);
  }
}

class LargeLogoHeader extends StatelessWidget {
  final String title;

  const LargeLogoHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;
    return Column(
      children: [
        Image.asset(
          AppAssets.logo,
          width: compact ? 135 : 170,
          height: compact ? 95 : 120,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(height: compact ? 8 : 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 27 : 31,
            fontWeight: FontWeight.w900,
            letterSpacing: .3,
          ),
        ),
      ],
    );
  }
}

class RealMap extends StatelessWidget {
  final LatLng center;
  final LatLng? searchedPoint;
  final String? searchedName;
  final LatLng? routeOriginPoint;
  final String? routeOriginName;
  final ValueChanged<Station>? onStationTap;
  final VoidCallback? onLocationPressed;
  final List<LatLng> routePoints;
  final List<Station>? customStations;
  final ValueChanged<GoogleMapController>? onMapCreated;

  const RealMap({
    super.key,
    this.center = diosPadreCenter,
    this.searchedPoint,
    this.searchedName,
    this.routeOriginPoint,
    this.routeOriginName,
    this.onStationTap,
    this.onLocationPressed,
    this.routePoints = const [],
    this.customStations,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final stationList = customStations ?? stations;

    final mapMarkers = <Marker>{
      ...stationList.map(
        (station) => Marker(
          markerId: MarkerId('station_${station.name}'),
          position: station.point,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.bikes} bicicletas disponibles',
          ),
          onTap: () => onStationTap?.call(station),
        ),
      ),
      if (routeOriginPoint != null)
        Marker(
          markerId: const MarkerId('route_origin'),
          position: routeOriginPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: routeOriginName ?? 'Origen',
            snippet: 'Origen',
          ),
        ),
      if (searchedPoint != null)
        Marker(
          markerId: const MarkerId('searched_place'),
          position: searchedPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: searchedName ?? 'Lugar seleccionado',
            snippet: routeOriginPoint != null ? 'Destino' : 'Ubicación seleccionada',
          ),
        ),
    };

    final mapPolylines = <Polyline>{
      if (routePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('bikezone_route'),
          points: routePoints,
          width: 6,
          color: AppColors.lime,
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: 14.2,
            ),
            onMapCreated: onMapCreated,
            markers: mapMarkers,
            polylines: mapPolylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          if (onLocationPressed != null)
            Positioned(
              right: 12,
              bottom: 34,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: onLocationPressed,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}


class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lime),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 62,
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.lime,
                  size: 57,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(fontSize: 21),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      '${station.bikes} Bicicletas',
                      style: const TextStyle(fontSize: 19),
                    ),
                  ],
                ),
              ),
              Text(
                '${station.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class RoutePlace {
  final String name;
  final LatLng point;

  const RoutePlace({
    required this.name,
    required this.point,
  });
}

const routePlaces = <RoutePlace>[
  RoutePlace(name: 'Centro de Ixmiquilpan', point: centroIxmiquilpan),
  RoutePlace(name: 'El Nith', point: elNith),
  RoutePlace(name: 'El Fitzhi', point: elFitzhi),
  RoutePlace(name: 'La Otra Banda', point: laOtraBanda),
  RoutePlace(name: 'Dios Padre', point: diosPadreCenter),
  RoutePlace(name: 'Panales', point: panales),
  RoutePlace(name: 'Maguey Blanco', point: magueyBlanco),
  RoutePlace(name: 'Taxadho', point: taxadho),
  RoutePlace(name: 'Cantinela', point: cantinela),
  RoutePlace(name: 'Orizabita', point: orizabita),
  RoutePlace(name: 'Balneario Dios Padre', point: balnearioDiosPadre),
  RoutePlace(name: 'Balneario La Media Luna', point: balnearioMediaLuna),
  RoutePlace(name: 'UTVM', point: utvm),
];

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  static Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$coordinates'
      '?overview=full&geometries=geojson&steps=false',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'BikeZone university Flutter application',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = body['routes'] as List<dynamic>? ?? const [];

        if (routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates =
              geometry['coordinates'] as List<dynamic>? ?? const [];

          final points = coordinates.map((coordinate) {
            final values = coordinate as List<dynamic>;
            return LatLng(
              (values[1] as num).toDouble(),
              (values[0] as num).toDouble(),
            );
          }).toList();

          if (points.isNotEmpty) {
            return RouteResult(
              points: points,
              distanceKm:
                  ((route['distance'] as num?)?.toDouble() ?? 0) / 1000,
              durationMinutes:
                  ((route['duration'] as num?)?.toDouble() ?? 0) / 60,
            );
          }
        }
      }
    } catch (_) {}

    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    return RouteResult(
      points: [origin, destination],
      distanceKm: distanceMeters / 1000,
      durationMinutes: (distanceMeters / 1000) * 4,
    );
  }
}

class BikeTypeCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const BikeTypeCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.limeDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Image.asset(
                image,
                width: 150,
                height: 110,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class BikeOption {
  final String name;
  final String image;
  final bool available;

  const BikeOption(this.name, this.image, this.available);
}

class BikeCard extends StatelessWidget {
  final BikeOption bike;
  final VoidCallback? onTap;

  const BikeCard({
    super.key,
    required this.bike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 105),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.limeDark),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Image.asset(
                bike.image,
                width: 128,
                height: 92,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bike.name),
                    const SizedBox(height: 8),
                    Text(
                      bike.available ? 'Disponible' : 'No disponible',
                      style: TextStyle(
                        color: bike.available
                            ? AppColors.lime
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}


class _RideMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RideMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.limeDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lime,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReservationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.lime,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleAdminButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SimpleAdminButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.lime, size: 28),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: AppColors.limeDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}

class _AdminListScaffold extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) itemBuilder;

  const _AdminListScaffold({
    required this.title,
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar los datos.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            );
          }

          final docs = snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: AppColors.lime,
                    size: 52,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Aún no hay registros.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => itemBuilder(docs[index]),
          );
        },
      ),
    );
  }
}

class _AdminDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _AdminDataCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.limeDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lime, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      line,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileAction({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 31, color: Colors.white),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(fontSize: 17)),
        ],
      ),
    );
  }
}

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.limeDark),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history,
            color: AppColors.lime,
            size: 38,
          ),
          SizedBox(height: 8),
          Text('Todavía no tienes reservaciones.'),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final ReservationRecord record;

  const HistoryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.limeDark),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pedal_bike,
            color: AppColors.lime,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.bike),
                const SizedBox(height: 4),
                Text(
                  '${record.station} • ${record.hours} h',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  record.date,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${record.price}',
            style: const TextStyle(
              color: AppColors.lime,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 103,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.limeDark),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.lime, size: 36),
              const SizedBox(height: 7),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.lime),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          disabledBackgroundColor: AppColors.limeDark,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  final String text;

  const PageTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: .6,
      ),
    );
  }
}
