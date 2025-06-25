import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/pages/location_selection_page.dart';
import 'package:kreisel_frontend/services/admin_service.dart';
import 'package:kreisel_frontend/pages/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Container(
                  width: 240, // Changed from 120
                  height: 240, // Changed from 120
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      60,
                    ), // Increased from 30 to maintain proportion
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading logo: $error');
                      // Fallback Icon auch größer machen
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          CupertinoIcons.cube_box,
                          size: 120, // Increased from 60
                          color: Color(0xFF007AFF),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'HM Sportsgear',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'HM Equipment Verleih',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 48),

                // Form Fields
                if (_isRegistering)
                  _buildTextField(
                    controller: _fullNameController,
                    placeholder: 'Vollständiger Name',
                    icon: CupertinoIcons.person,
                  ),
                _buildTextField(
                  controller: _emailController,
                  placeholder: 'E-Mail (@hm.edu)',
                  icon: CupertinoIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _passwordController,
                  placeholder: 'Passwort',
                  icon: CupertinoIcons.lock,
                  isPassword: true,
                ),

                SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: CupertinoButton(
                    color: Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _isLoading ? null : _handleAuth,
                    child:
                        _isLoading
                            ? CupertinoActivityIndicator(color: Colors.white)
                            : Text(
                              _isRegistering ? 'Registrieren' : 'Anmelden',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                SizedBox(height: 16),

                // Toggle Button
                CupertinoButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _isRegistering = !_isRegistering;
                              // Clear form when switching
                              _emailController.clear();
                              _passwordController.clear();
                              _fullNameController.clear();
                            });
                          },
                  child: Text(
                    _isRegistering
                        ? 'Bereits registriert? Anmelden'
                        : 'Noch kein Account? Registrieren',
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : Color(0xFF007AFF),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        enabled: !_isLoading,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
      ),
    );
  }

  void _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAlert('Fehler', 'Bitte alle Felder ausfüllen');
      return;
    }

    if (!_emailController.text.trim().endsWith('@hm.edu')) {
      _showAlert('Fehler', 'Nur HM E-Mail-Adressen sind erlaubt');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // Check if this is an admin email
      if (email.startsWith('admin')) {
        if (_isRegistering) {
          // Admin registration
          await AdminService.register(
            _fullNameController.text.trim(),
            email,
            password,
          );
          print('DEBUG: Admin registration successful');
        } else {
          // Admin login
          await AdminService.login(email, password);
          print('DEBUG: Admin login successful');
        }

        // Navigate to admin dashboard
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => AdminDashboard()),
        );
      } else {
        // Regular user authentication
        if (_isRegistering) {
          await AuthStateManager.register(
            _fullNameController.text.trim(),
            email,
            password,
          );
        } else {
          await AuthStateManager.login(email, password);
        }

        // Navigate to location selection
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => LocationSelectionPage()),
        );
      }
    } catch (e) {
      print('Auth Error: $e');
      if (mounted) {
        _showAlert('Fehler', _formatErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      error = error.substring(11);
    }

    // Handle common error messages
    if (error.contains('Failed to parse')) {
      return 'Server-Fehler: Ungültige Antwort';
    }
    if (error.contains('Connection refused') ||
        error.contains('Connection failed')) {
      return 'Verbindung zum Server fehlgeschlagen';
    }
    if (error.contains('Authentication required')) {
      return 'Anmeldung erforderlich';
    }
    if (error.contains('User already exists') ||
        error.contains('already registered')) {
      return 'Benutzer bereits registriert';
    }
    if (error.contains('Invalid credentials') ||
        error.contains('Wrong password')) {
      return 'Ungültige Anmeldedaten';
    }
    if (error.contains('User not found')) {
      return 'Benutzer nicht gefunden';
    }

    return error.isNotEmpty ? error : 'Ein unbekannter Fehler ist aufgetreten';
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
