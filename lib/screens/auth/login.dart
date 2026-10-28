part of '../../main.dart';

class LoginPage extends StatefulWidget {
  final String? initialProvider;
  const LoginPage({super.key, this.initialProvider});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialProvider == 'google') loginGoogle();
      if (widget.initialProvider == 'facebook') loginFacebook();
    });
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _openByRole() async {
    try {
      final role = await UserStore.role();

      debugPrint('LOGIN DEBUG ROLE: $role');

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          fadeRoute(const AdminPage()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          fadeRoute(const MainPage()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('ERROR LEYENDO ROL: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo leer el rol del usuario: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final valid = await UserStore.login(email.text, password.text);

      if (!valid) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Credenciales incorrectas.',
        );
      }

      await _openByRole();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Correo o contraseña incorrectos.';

      if (e.code == 'invalid-email') {
        message = 'El correo no es válido.';
      } else if (e.code == 'user-disabled') {
        message = 'Esta cuenta está deshabilitada.';
      } else if (e.code == 'network-request-failed') {
        message = 'Revisa tu conexión a internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loginGoogle() async {
    setState(() => loading = true);

    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google no devolvió un ID Token.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = result.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Google.');
      }

      await UserStore.ensureSocialUser(
        user: user,
        provider: 'google',
      );

      await _openByRole();
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar con Google: ${e.code.name}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar con Google: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loginFacebook() async {
    setState(() => loading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        return;
      }

      if (result.status != LoginStatus.success ||
          result.accessToken == null) {
        throw Exception(
          result.message ?? 'Facebook no devolvió un token válido.',
        );
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = authResult.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Facebook.');
      }

      await UserStore.ensureSocialUser(
        user: user,
        provider: 'facebook',
      );

      await _openByRole();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar con Facebook: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const LargeLogoHeader(title: 'INICIAR SESIÓN'),
                const SizedBox(height: 36),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 17),
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Ingresa tu contraseña.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),
                AppButton(
                  text: loading ? 'INGRESANDO...' : 'INGRESAR',
                  width: 190,
                  onPressed: loading ? null : login,
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.muted)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continúa con',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : loginGoogle,
                    icon: const Icon(
                      Icons.g_mobiledata,
                      color: Colors.white,
                      size: 30,
                    ),
                    label: const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.limeDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : loginFacebook,
                    icon: const Icon(
                      Icons.facebook,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      'Continuar con Facebook',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.limeDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('¿No tienes una cuenta?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    fadeRoute(const RegisterPage()),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(color: AppColors.lime),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Ingresa tu correo.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

