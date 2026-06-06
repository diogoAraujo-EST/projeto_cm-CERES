import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import 'login_bottom_sheet.dart';     
import 'register_bottom_sheet.dart';  

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginBottomSheet(
        onSwitchToRegister: () {
          Navigator.pop(context); 
          _showRegisterSheet(context); 
        },
      ),
    );
  }

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegisterBottomSheet(
        onSwitchToLogin: () {
          Navigator.pop(context); 
          _showLoginSheet(context); 
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          Positioned(
            left: -screenWidth * 0.85, 
            top: screenHeight * 0.10, 
            bottom: screenHeight * 0.35, 
            child: Image.asset(
              'assets/images/planta_welcome.png',
              fit: BoxFit.contain, 
            ),
          ),
          Positioned(
            right: 24,
            top: screenHeight * 0.25,
            width: screenWidth * 0.52, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/ceres_logo_only_2.png',
                  height: 80,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 38, 
                      fontWeight: FontWeight.bold, 
                      color: CERESColors.textMain, 
                      height: 1.1, 
                    ),
                    children: [
                      TextSpan(text: 'Cuida\ndas tuas\n'),
                      TextSpan(
                        text: 'plantas', 
                        style: TextStyle(color: CERESColors.primaryDarkGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A rega certa,\nna altura certa.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CERESColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showRegisterSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CERESColors.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Começar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLoginSheet(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Entrar', style: TextStyle(fontSize: 16, color: CERESColors.textMain, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}