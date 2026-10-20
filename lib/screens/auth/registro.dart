part of '../../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await UserStore.register(
        name: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Ahora inicia sesión.'),
          backgroundColor: AppColors.limeDark,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        fadeRoute(const LoginPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'No se pudo registrar el usuario.';

      if (e.code == 'email-already-in-use') {
        message = 'Este correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo electrónico no es válido.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'network-request-failed') {
        message = 'Revisa tu conexión a internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error: $e'),
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
                const LargeLogoHeader(title: 'REGISTRO'),
                const SizedBox(height: 18),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) return 'Ingresa tu nombre completo.';
                    if (RegExp(r'\d').hasMatch(text)) {
                      return 'El nombre no debe contener números.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (!RegExp(r'^\d{10}$').hasMatch(value?.trim() ?? '')) {
                      return 'Ingresa exactamente 10 dígitos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 13),
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
                    if ((value ?? '').length < 8) {
                      return 'Usa por lo menos 8 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: confirm,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (value) {
                    if (value != password.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),
                AppButton(
                  text: loading ? 'REGISTRANDO...' : 'REGISTRARSE',
                  width: 210,
                  onPressed: loading ? null : register,
                ),
                const SizedBox(height: 13),
                const Text('¿Ya tienes una cuenta?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    fadeRoute(const LoginPage()),
                  ),
                  child: const Text(
                    'Iniciar sesión',
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

