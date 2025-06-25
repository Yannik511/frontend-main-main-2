import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/pages/login_page.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = ApiService.currentUser?.fullName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      _showAlert('Fehler', 'Name darf nicht leer sein');
      return;
    }

    if (newName == ApiService.currentUser?.fullName) {
      _showAlert('Info', 'Name wurde nicht geändert');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = await ApiService.updateUserName(newName);

      if (mounted) {
        setState(() {
          _nameController.text = updatedUser.fullName;
          _isLoading = false;
        });
        _showAlert('Erfolg', 'Name wurde aktualisiert');
      }
    } catch (e) {
      print('DEBUG: Name update error: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        if (e.toString().contains('Sitzung abgelaufen')) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
          return;
        }

        _showAlert('Fehler', e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _updatePassword() async {
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    if (currentPass.isEmpty || newPass.isEmpty) {
      _showAlert('Fehler', 'Bitte beide Passwörter eingeben');
      return;
    }

    if (newPass.length < 6) {
      _showAlert(
        'Fehler',
        'Neues Passwort muss mindestens 6 Zeichen lang sein',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.updatePassword(currentPass, newPass);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      if (mounted) {
        _showAlert('Erfolg', 'Passwort wurde aktualisiert');
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Fehler', 'Passwort konnte nicht aktualisiert werden');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Fehler', 'Abmelden fehlgeschlagen');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Name ändern', [
            _buildTextField(
              controller: _nameController,
              placeholder: 'Name',
              icon: CupertinoIcons.person,
            ),
            SizedBox(height: 16),
            _buildButton('Name aktualisieren', _updateName),
          ]),

          SizedBox(height: 32),

          _buildSection('Passwort ändern', [
            _buildTextField(
              controller: _currentPasswordController,
              placeholder: 'Aktuelles Passwort',
              icon: CupertinoIcons.lock,
              isPassword: true,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              placeholder: 'Neues Passwort',
              icon: CupertinoIcons.lock,
              isPassword: true,
            ),
            SizedBox(height: 16),
            _buildButton('Passwort ändern', _updatePassword),
          ]),

          // Trennlinie
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Divider(color: Colors.grey.withOpacity(0.3)),
          ),

          // Abmelde-Button
          _buildButton(
            'Abmelden',
            _logout,
            isDestructive: true,
            icon: CupertinoIcons.square_arrow_right,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
                  ),
                  Expanded(
                    child: Text(
                      'Mein Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    bool isDestructive = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 12),
        color: isDestructive ? Color(0xFFFF453A) : Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(12),
        onPressed: _isLoading ? null : onPressed,
        child:
            _isLoading
                ? CupertinoActivityIndicator(color: Colors.white)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
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
