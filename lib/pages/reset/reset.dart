import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/pages/login/login_page.dart';
import 'package:food/services/auth_service.dart';
import 'package:food/widget/custom_dialog.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}
class _ResetPageState extends State<ResetPage> with SingleTickerProviderStateMixin<ResetPage> {
  final AuthService _authService = AuthService();
  late final AnimationController resetButtonController;
  late final Animation<double> buttonSqueezeAnimation;

  final TextEditingController _emailResetController = TextEditingController();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    resetButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    buttonSqueezeAnimation = Tween(
      begin: 320.0,
      end: 70.0,
    ).animate(
      CurvedAnimation(
        parent: resetButtonController,
        curve: const Interval(
          0.0,
          0.250,
        ),
      ),
    );
  }

  @override
  void dispose() {
    resetButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(0xBF),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: Colors.transparent,
              width: double.infinity,
              height: kToolbarHeight,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: emailTextField(),
                      ),
                      const SizedBox(height: 32.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: resetButton(),
                      ),
                      const SizedBox(height: 32.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: backButton(),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget emailTextField() {
    return TextField(
      controller: _emailResetController,
      autocorrect: true,
      decoration: const InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.0),
          child: Icon(Icons.email, color: Colors.white,),
        ),
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.white),
      ),
      keyboardType: TextInputType.emailAddress,
      maxLines: 1,
      style: const TextStyle(fontSize: 16.0, color: Colors.white),
      textInputAction: TextInputAction.next,
      autofocus: false,
      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget resetButton() {
    return AnimatedBuilder(
      animation: buttonSqueezeAnimation,
      builder: (context, child) {
        final value = buttonSqueezeAnimation.value;

        return SizedBox(
          width: value,
          height: 60.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.greenAccent,
                width: 2.0,
              ),
            ),
            child: Material(
              elevation: 5.0,
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.0),
              child: child
            ),
          ),
        );
      },
      child: MaterialButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          _sendResetMail();
        },
        color: Colors.transparent,
        splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        child: const Text(
          'Reset',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Widget backButton() {
    return AnimatedBuilder(
      animation: buttonSqueezeAnimation,
      builder: (context, child) {
        final value = buttonSqueezeAnimation.value;

        return SizedBox(
          width: value,
          height: 60.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.deepOrangeAccent,
                width: 2.0,
              ),
            ),
            child: Material(
            elevation: 5.0,
            clipBehavior: Clip.antiAlias,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24.0),
            child: child
          ),
          ),
        );
      },
      child: MaterialButton(
        onPressed: () {
          Navigator.pushReplacement(context,CupertinoPageRoute(builder: (context) => const LoginPage()));
        },
        color: Colors.transparent,
        splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        child: const Text(
          'Back to Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  void _sendResetMail() async {
    String email = _emailResetController.text.trim();
    if (email.isNotEmpty) {
      try {
        await _authService.sendPasswordResetEmail(email);

        if (mounted) {
          showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: 'Success',
                    message: 'Password reset email sent successfully.',
                  );
                },
              );
        }
      } catch (e) {
        if (mounted){
          showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: 'Failed',
                    message: 'Failed to send password reset email.',
                  );
                },
              );
        }        
      }
    } else {
      showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: '',
                    message: 'Please enter your email address.',
                  );
                },
              );
    }
  }

}
