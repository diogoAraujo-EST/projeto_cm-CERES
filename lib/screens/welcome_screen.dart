import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'main_nav_screen.dart'; 

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          Positioned(
            left: -screenWidth * 0.20, 
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
            width: screenWidth * 0.55, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.eco_outlined, 
                  color: CERESColors.primaryDarkGreen, 
                  size: 32
                ),
                const SizedBox(height: 16),
                
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(true),
                      const SizedBox(width: 8),
                      _buildDot(false),
                      const SizedBox(width: 8),
                      _buildDot(false),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavScreen()),
                        );
                      },
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
                  
                  // Entrar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
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

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8, 
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? CERESColors.primaryDarkGreen : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}