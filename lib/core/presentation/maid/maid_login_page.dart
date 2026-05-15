import 'package:bookmyservice/core/presentation/maid/page/maid_bookings_page.dart';
import 'package:bookmyservice/core/presentation/maid/services/current_maid_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin/login_page.dart';

class MaidLoginPage extends ConsumerStatefulWidget {
  const MaidLoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MaidLoginPage> createState() => _MaidLoginPageState();
}

class _MaidLoginPageState extends ConsumerState<MaidLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool hidePassword = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final success = await ref
        .read(currentMaidProvider.notifier)
        .loginWithUsernameAndPassword(
            usernameController.text.trim(), passwordController.text.trim());

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const MaidBookingsPage()),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/Time Bachao.png', // Place your generated logo here
                  height: 200,
                ),
                const SizedBox(height: 16),
                // App Name
                Text(
                  'Time Bachao',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(1),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Text(
                              "Login as Maid",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: "Username",
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? "Enter username"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              obscureText: hidePassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() {
                                    hidePassword = !hidePassword;
                                  }),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? "Enter password"
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[500],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _login,
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: Colors.teal[500],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Login as Admin",
                    style: TextStyle(
                        //color: Colors.white,
                        ),
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
