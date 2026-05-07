import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class ResponsiveHeader extends StatelessWidget {
  const ResponsiveHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final double height = isDesktop ? 300 : 220;
    final double fontSize = isDesktop ? 70 : 50;

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'PriceCollector',
              style: GoogleFonts.montserratAlternates(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Image.asset(
              'assets/images/carrinho.png',
              width: isDesktop ? 150 : 103,
              height: isDesktop ? 120 : 81,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
