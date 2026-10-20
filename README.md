# 🚲 BikeZone — Aplicación móvil de renta de bicicletas

BikeZone es una aplicación móvil desarrollada con Flutter y Dart que permite a los usuarios consultar estaciones de bicicletas, explorar rutas, realizar reservaciones y registrar recorridos.

El proyecto utiliza Firebase para la autenticación y almacenamiento de información, además de Google Maps para visualizar ubicaciones.

## Funcionalidades

### Cliente
- Registro e inicio de sesión.
- Autenticación mediante correo electrónico, Google y Facebook.
- Consulta de estaciones de bicicletas.
- Visualización de mapas y búsqueda de ubicaciones.
- Consulta de bicicletas disponibles.
- Registro y consulta de reservaciones.
- Seguimiento y registro de recorridos.
- Consulta y actualización del perfil.

### Administrador
- Acceso mediante rol de administrador.
- Panel de administración.
- Gestión de usuarios.
- Consulta y administración de reservaciones.
- Gestión de rutas.

## Tecnologías utilizadas

- Flutter y Dart.
- Firebase Authentication.
- Cloud Firestore.
- Google Maps.
- Geolocator.
- APIs de búsqueda y consulta de ubicaciones.

## Organización del proyecto

La carpeta `lib` se encuentra organizada por pantallas:

- `screens/auth/`: bienvenida, inicio de sesión y registro.
- `screens/cliente/`: funcionalidades del cliente.
- `screens/admin/`: funcionalidades del administrador.
- `services/`: servicios de la aplicación.
- `main.dart`: inicialización y configuración principal.

## Versionamiento

El proyecto utiliza Git y GitHub para controlar los cambios.

- `main`: rama principal estable.
- `feature/*`: ramas para desarrollar funcionalidades o realizar modificaciones.
- Commits descriptivos para registrar cambios.
- Tags para identificar versiones importantes.
- GitHub Releases para publicar archivos APK.

**Primera versión:** `v1.0.0`.

## Instalación

Para instalar BikeZone en Android, accede a la sección Releases del repositorio, descarga el archivo `app-release.apk` e instálalo en un dispositivo compatible.

## Repositorio

https://github.com/Jessicakljo0/MovilBikeZone

## Descarga de la aplicación

https://github.com/Jessicakljo0/MovilBikeZone/releases/tag/v1.0.0