import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:food/services/auth_service.dart';

class TopSection extends StatelessWidget {

  const TopSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final authState = authService.authState;

    String headerText;
    if (authState == AuthState.register) {
      headerText = "Register";
    } else if (authState == AuthState.forgotPassword) {
      headerText = "Reset Password";
    } else {
      headerText = "Login";
    }

    return Container(
      height: 400,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: <Widget>[
          _buildLightImage('assets/images/light-1.png', left: 30, width: 80, height: 200, delay: 800),
          _buildLightImage('assets/images/light-2.png', left: 140, width: 80, height: 150, delay: 1000),
          _buildLightImage('assets/images/clock.png', right: 40, top: 40, width: 80, height: 150, delay: 1100),
          Positioned(
            top: 150,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1400),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  child: Center(
                    child: Text(
                      headerText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightImage(String imagePath, {double? left, double? top, double? right, double? width, double? height, required int delay}) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      width: width,
      height: height,
      child: FadeInDown(
        duration: Duration(milliseconds: delay),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath)
            )
          ),
        ),
      ),
    );
  }
}
