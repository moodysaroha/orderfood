import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:food/main.dart';
import 'package:food/pages/register/register.dart';
import 'package:food/pages/reset/reset.dart';
import 'package:food/services/auth_service.dart';
import 'package:food/widget/custom_dialog.dart';
import '../../widget/topsection_widget.dart';
import '../../widget/main_content_widget.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin<LoginPage> {
  bool isLoading = false;
  final AuthService _authService = AuthService();

  final FirebaseAuth _authFB = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late final AnimationController loginButtonController;
  late final Animation<double> buttonSqueezeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  bool _obscureText = true;

  bool isEmailValid = true;
  bool isPasswordValid = true;

  final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    caseSensitive: false,
    multiLine: false,
  );

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      isEmailValid = _emailRegex.hasMatch(email);
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      if (password.length >= 6) {
        isPasswordValid = true;
      } else {
        isPasswordValid = false;
      }
    });
  }


  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);

    loginButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    buttonSqueezeAnimation = Tween(
      begin: 320.0,
      end: 70.0,
    ).animate(
      CurvedAnimation(
        parent: loginButtonController,
        curve: const Interval(
          0.0,
          0.250,
        ),
      ),
    );
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    loginButtonController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await _authFB.signInWithCredential(credential);
      final User? user = authResult.user;

      bool isNewUser = false;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(FirebaseFirestore.instance.collection('users').doc(user!.uid));

        if (!snapshot.exists) {
          transaction.set(FirebaseFirestore.instance.collection('users').doc(user!.uid), {'name': user.displayName});
          isNewUser = true;
        }
      });

      if (isNewUser) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      } else {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } catch (e) {
      print(e);
    }
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: passwordTextField(),
                      ),
                      const SizedBox(height: 32.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: loginButton(),
                      ),
                      const SizedBox(height: 32.0),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: needAnAccount(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: forgotPassword(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _signInWithGoogle(context);
                          },
                          child: Text('Sign in  Google'),
                        ),
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
      controller: _emailController,
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
        FocusScope.of(context).requestFocus(passwordFocusNode);
      },
    );
  }

  Widget passwordTextField() {
    Color labelColor = isPasswordValid ? Colors.white : Colors.red;
    Color iconColor = isPasswordValid ? Colors.white : Colors.red;
    return TextField(
      controller: _passwordController,
      autocorrect: true,
      obscureText: _obscureText,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureText = !_obscureText),
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          iconSize: 18.0,
        ),
        labelText: 'Password',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: Icon(Icons.lock, color: iconColor),
        ),
      ),
      keyboardType: TextInputType.text,
      maxLines: 1,
      style: const TextStyle(fontSize: 16.0, color: Colors.white),
      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
      textInputAction: TextInputAction.done,
      focusNode: passwordFocusNode
    );
  }

  Widget loginButton() {
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
              child: !isLoading
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        backgroundColor: Colors.green,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
            ),
          ),
        );
      },
      child: MaterialButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          setState(() {
            isLoading = true;
          });
          _login();
        },
        color: Colors.transparent,
        splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        child: const Text(
          'LOGIN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Widget needAnAccount() {
    return TextButton(
      onPressed: () async {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => const RegisterPage(),
          ),
        );
      },
      child: const Text(
        "Don't have an account? Sign up",
        style: TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget forgotPassword() {
    return TextButton(
      onPressed: () async {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => const ResetPage(),
          ),
        );
      },
      child: const Text(
        'Forgot password?',
        style: TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget signInWithGoogle() {
    return ElevatedButton(
      onPressed: () async {
        User? user = await _authService.signInWithGoogle();
        if (user != null) {
          print('Signed in as ${user.displayName}');
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed.'),backgroundColor: Colors.red,),);
          }
      },
      child: Text('Sign in with Google'),
    );
  }

  void _login() async {

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (isEmailValid && isPasswordValid){
      try {
        await _authService.login(email, password);

        if (_authService.isLoggedIn) {
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful.'),
              backgroundColor: Colors.green,
            ),
            );
            Navigator.push(context,MaterialPageRoute(builder: (context) => const MainWrapper()),);
          }
        } else {
          isLoading = false;
          if(mounted){
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: 'Error',
                    message: 'Login failed.',
                  );
                },
              );
          }
        }
      } catch (e) {
        if(mounted){
          showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: 'Error',
                    message: 'Login failed.',
                  );
                },
              );
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Check Credentials.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }

  }

}
