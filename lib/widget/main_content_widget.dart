import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food/main.dart';
import 'package:food/services/auth_service.dart';
import 'package:food/widget/custom_dialog.dart';

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  MainContentState createState() => MainContentState();
}

class MainContentState extends State<MainContent> with SingleTickerProviderStateMixin{
  bool isLoading = false;
  
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailResetController = TextEditingController();

  bool isEmailValid = true;
  bool isPasswordMatched = true;

  final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    caseSensitive: false,
    multiLine: false,
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);

    _emailResetController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmPasswordController.dispose();
    _passwordController.dispose();

    _emailResetController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      isEmailValid = _emailRegex.hasMatch(email);
    });
  }

  void _validatePassword() {
    setState(() {
      isPasswordMatched =
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: <Widget>[
          _buildPageTransitionSwitcher(authService),
          _buildToggleAuthButton(authService),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildPageTransitionSwitcher(AuthService authService) {
  return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _getCurrentAuthForm(authService),
  );
  }
  
  Widget _buildToggleAuthButton(AuthService authService) {
    return Visibility(
      visible: authService.authState != AuthState.forgotPassword,
      child: TextButton(
        onPressed: () {
          authService.setAuthState(authService.authState == AuthState.login ? AuthState.register : AuthState.login);
        },
        child: Text(authService.authState == AuthState.register ? "Already have an account? Login here" : "Don't have an account? Register here"),
      ),
    );
  }

  Widget _getCurrentAuthForm(AuthService authService) {
    switch (authService.authState) {
      case AuthState.login:
        return _buildLoginSection(authService);
      case AuthState.register:
        return _buildRegistrationSection(authService);
      case AuthState.forgotPassword:
        return _buildForgotPasswordSection(authService);
      default:
        return _buildLoginSection(authService);
    }
  }

  Widget _buildLoginSection(AuthService authService) {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildEmailAndPasswordFields(),
        const SizedBox(height: 30),
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildForgotPasswordLink(authService)
      ],
    );
  }

  Widget _buildRegistrationSection(AuthService authService) {
    return Column(
      key: const ValueKey('register'),
      children: [
        _buildEmailAndPasswordConfirmFields(),
        const SizedBox(height: 30),
        _buildRegisterButton(authService)
      ],
    );
  }

  Widget _buildForgotPasswordSection(AuthService authService) {
    return Column(
      key: const ValueKey('forgotPassword'),
      children: [
        _buildForgotPasswordFields(),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () => _sendResetMail(),
          child: const Text("Send Reset Email"),
        ),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            authService.setAuthState(AuthState.login);
          },
          child: const Text("Back to Sign In"),
        ),
      ],
    );
  }

  Widget _buildEmailAndPasswordFields() {
    return 
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(143, 148, 251, 1)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(143, 148, 251, .2),
              blurRadius: 20.0,
              offset: Offset(0, 10)
            )
          ]
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.grey[700])
              ),
            ),
            Divider(
              color: Colors.grey[400],
              thickness: 1,
              height: 20,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.grey[700])
              ),
            )
          ],
        ),
      );
  }

  Widget _buildLoginButton() {    
    return 
      GestureDetector(
        onTap: () => _login( () {
          setState(() {
            isLoading = true;
          });
        }),
        child: Container(
          height: 50,          
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(70, 70, 251, 1),
                Color.fromRGBO(70, 70, 251, .6),
              ]
            )
          ),
          child: Center(
            child: isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      );
  }

  Widget _buildForgotPasswordLink(AuthService authService) {
    return TextButton(
      onPressed: () {
        authService.setAuthState(AuthState.forgotPassword);
      },
      child: const Text(
        "Forgot Password?",
        style: TextStyle(color: Color.fromRGBO(143, 148, 251, 1))
      ),
    );
  }

  Widget _buildForgotPasswordFields() {
    return 
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(143, 148, 251, 1)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(143, 148, 251, .2),
              blurRadius: 20.0,
              offset: Offset(0, 10)
            )
          ]
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailResetController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.grey[700])
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildEmailAndPasswordConfirmFields() {
    return 
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(143, 148, 251, 1)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(143, 148, 251, .2),
              blurRadius: 20.0,
              offset: Offset(0, 10)
            )
          ]
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.grey[700]),
                errorText: isEmailValid ? null : 'Enter a valid email',
              ),
            ),
            Divider(
              color: Colors.grey[400],
              thickness: 1,
              height: 20,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Confirm Password",
                hintStyle: TextStyle(color: Colors.grey[700]),
                errorText:
                  isPasswordMatched ? null : 'Passwords do not match',
              ),
            ),
            Divider(
              color: Colors.grey[400],
              thickness: 1,
              height: 20,
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.grey[700]),
                errorText:
                  isPasswordMatched ? null : 'Passwords do not match',
              ),
            ),                    
          ],
        ),
      );
    }

  Widget _buildRegisterButton(AuthService authService) {
    return 
      GestureDetector(
        onTap: () {
          setState(() {
            isLoading = true;
          });
          _register(authService);
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color.fromRGBO(70, 70, 251, 1),
                Color.fromRGBO(70, 70, 251, .6),
              ]
            )
          ),
          child: Center(
            child: isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text("Register", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  void _register(AuthService authService) async {
    if (_validateFormData()) {
      Map<String, dynamic> userData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      try {
        await authService.registeruser(userData);

        if (authService.isLoggedIn) {
          if(mounted){
            _showSnackBar('Registration Successful.', Colors.green);
            Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainWrapper()),
                      );
          }
        } else {
          isLoading = false;
          if(mounted){
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: 'Error',
                    message: 'Registration failed.',
                  );
                },
              );
          }
        }
      } catch (e) {
        isLoading = false;
        var errorMessage = e.toString();
        if (errorMessage.contains('Invalid password string')) {
          errorMessage = 'Invalid password: Password must be at least 6 characters long.';
        }
        if(mounted){
          showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomAlertDialog(
                    title: 'Error',
                    message: errorMessage,
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
  }

  bool _validateFormData() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      if(mounted){
        showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: '',
                    message: 'Please enter your email.',
                  );
                },
              );
      }
      return false;
    }

    if (!_emailRegex.hasMatch(email)) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const CustomAlertDialog(
              title: '',
              message: 'Please enter a valid email address.',
            );
          },
        );
      }
      return false;
    }

    if (password.isEmpty) {
      showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const CustomAlertDialog(
                    title: '',
                    message: 'Please enter your password.',
                  );
                },
              );
      return false;
    }

    return true;
  }

  void _login(Function preLoginCallback) async {
    preLoginCallback();

    if (_validateFormData()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text;

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
            Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainWrapper()),
                      );
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
      isLoading = false;
    }
  }

}
