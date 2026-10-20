part of '../../main.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            final logoHeight = compact ? 92.0 : 118.0;
            final bikeHeight = compact ? 215.0 : 270.0;

            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 18),
              child: Column(
                children: [
                  Image.asset(
                    AppAssets.logo,
                    width: compact ? 135 : 165,
                    height: logoHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  Text(
                    'BIKEZONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 39 : 45,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Muévete de forma',
                    style: TextStyle(
                      fontSize: compact ? 22 : 25,
                      height: 1.1,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'segura y sostenible',
                    style: TextStyle(
                      fontSize: compact ? 21 : 24,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        AppAssets.welcomeBike,
                        width: double.infinity,
                        height: bikeHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  AppButton(
                    text: 'INICIAR SESIÓN',
                    onPressed: () => Navigator.push(
                      context,
                      fadeRoute(const LoginPage()),
                    ),
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        fadeRoute(const RegisterPage()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lime,
                        side: const BorderSide(color: AppColors.lime),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'REGISTRARSE',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

