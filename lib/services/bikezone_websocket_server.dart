import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class BikeZoneWebSocketServer {
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  Timer? _metricsTimer;
  final Random _random = Random();

  bool routeActive = false;
  int elapsedSeconds = 0;
  double distance = 0;
  double speed = 0;
  int calories = 0;

  VoidCallback? onWatchConnected;
  VoidCallback? onWatchDisconnected;
  void Function(bool active)? onRouteStateChanged;
  void Function(String message)? onServerMessage;

  Future<void> start() async {
    if (_server != null) {
      onServerMessage?.call('El servidor WebSocket ya estaba iniciado');
      return;
    }

    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      4040,
    );

    onServerMessage?.call(
      'Servidor WebSocket activo en puerto 4040',
    );

    _server!.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _clients.add(socket);

        print('⌚ Watch conectado. Clientes: ${_clients.length}');
        onWatchConnected?.call();

        _sendTo(socket, {
          'type': 'route_state',
          'active': routeActive,
        });

        _sendMetricsTo(socket);

        socket.listen(
          (raw) {
            print('📩 Mensaje recibido del Watch: $raw');
            _handleMessage(socket, raw);
          },
          onDone: () => _removeClient(socket),
          onError: (error) {
            print('❌ Error WebSocket: $error');
            _removeClient(socket);
          },
          cancelOnError: true,
        );
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('BikeZone WebSocket Server')
          ..close();
      }
    });

    _startMetricsTimer();
  }

  void _removeClient(WebSocket socket) {
    final removed = _clients.remove(socket);

    if (removed) {
      print('❌ Watch desconectado');

      if (_clients.isEmpty) {
        onWatchDisconnected?.call();
      }
    }
  }

  Future<void> stop() async {
    _metricsTimer?.cancel();

    for (final client in _clients.toList()) {
      await client.close();
    }

    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void sendReservation({
    required String bike,
    required String station,
    required int hours,
    required int price,
    required String date,
  }) {
    _broadcast({
      'type': 'reservation',
      'bike': bike,
      'station': station,
      'hours': hours,
      'price': price,
      'date': date,
    });

    onServerMessage?.call(
      'Reserva enviada al Watch: $bike',
    );
  }

  void sendRoute({
    required String origin,
    required String destination,
    required double distanceKm,
    required int durationMinutes,
  }) {
    _broadcast({
      'type': 'selected_route',
      'origin': origin,
      'destination': destination,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
    });

    onServerMessage?.call(
      'Ruta enviada al Watch: $origin → $destination',
    );
  }

  void startRoute() {
    routeActive = true;
    elapsedSeconds = 0;
    distance = 0;
    speed = 0;
    calories = 0;

    _broadcast({
      'type': 'route_state',
      'active': true,
    });

    onRouteStateChanged?.call(true);
  }

  void stopRoute() {
    routeActive = false;
    speed = 0;

    _broadcast({
      'type': 'route_state',
      'active': false,
    });

    _broadcastMetrics();
    onRouteStateChanged?.call(false);
  }

  void _handleMessage(WebSocket socket, dynamic raw) {
    try {
      final data = jsonDecode(raw.toString()) as Map<String, dynamic>;

      if (data['type'] == 'watch_connected') {
        print('✅ Confirmación recibida del Watch');
        return;
      }

      if (data['type'] == 'route_action') {
        final action = data['action'];

        if (action == 'start') {
          startRoute();
        } else if (action == 'stop') {
          stopRoute();
        }
      }
    } catch (error) {
      print('❌ Mensaje inválido: $error');

      _sendTo(socket, {
        'type': 'error',
        'message': 'Mensaje inválido',
      });
    }
  }

  void _startMetricsTimer() {
    _metricsTimer?.cancel();

    _metricsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (routeActive) {
          elapsedSeconds++;
          speed = 12 + _random.nextDouble() * 9;
          distance += speed / 3600;
          calories = (distance * 28).round();
        } else {
          speed = 0;
        }

        _broadcastMetrics();
      },
    );
  }

  void _broadcastMetrics() {
    _broadcast({
      'type': 'metrics',
      'speed': double.parse(speed.toStringAsFixed(1)),
      'distance': double.parse(distance.toStringAsFixed(3)),
      'calories': calories,
      'elapsedSeconds': elapsedSeconds,
      'routeActive': routeActive,
    });
  }

  void _sendMetricsTo(WebSocket socket) {
    _sendTo(socket, {
      'type': 'metrics',
      'speed': double.parse(speed.toStringAsFixed(1)),
      'distance': double.parse(distance.toStringAsFixed(3)),
      'calories': calories,
      'elapsedSeconds': elapsedSeconds,
      'routeActive': routeActive,
    });
  }

  void _broadcast(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    final disconnected = <WebSocket>[];

    for (final client in _clients) {
      try {
        client.add(message);
      } catch (_) {
        disconnected.add(client);
      }
    }

    for (final client in disconnected) {
      _removeClient(client);
    }
  }

  void _sendTo(WebSocket socket, Map<String, dynamic> data) {
    try {
      socket.add(jsonEncode(data));
    } catch (_) {
      _removeClient(socket);
    }
  }
}

typedef VoidCallback = void Function();
