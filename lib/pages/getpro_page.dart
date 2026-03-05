import 'package:flutter/material.dart';
import 'package:food/utils/url_launcher.dart';

class GetProPage extends StatelessWidget {
  const GetProPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Colors.white,
        body:
          Column(
            children: [            
              Expanded(
                child: Column(
                  children: [
                    Stack(
                    children: [
                        CurvedGradientContainer(),
                        Positioned(
                          top: 20,
                          left: 10,
                          child: CloseButtonWhite(),
                        ),
                    ],
                    ),
                    SizedBox(height: 40),
                    FeatureList(),
                    Spacer(),
                    TryProButton(),
                    SizedBox(height: 10),
                    TermsAndPrivacyText(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class CloseButtonWhite extends StatelessWidget {
  const CloseButtonWhite({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class CurvedGradientContainer extends StatelessWidget {
  const CurvedGradientContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CurvedBottomClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    "Free for Limited Time!",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 60),
                const Text(
                  "All features Unlocked",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),               
              ],
          ),
          ),
      ),
    );
  }
}

class FeatureList extends StatelessWidget {
  const FeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeatureTile(title: 'No Ads'),
          FeatureTile(title: 'Generate images nonstop'),
          ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text('Save your improved shots'),
          ),          
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final String title;
  const FeatureTile({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check, color: Colors.green),
      title: Text(title),
    );
  }
}

class TryProButton extends StatelessWidget {
  const TryProButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'getProButton',
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            elevation: 20,
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Get Pro for \u20B90.0/ month', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

class TermsAndPrivacyText extends StatelessWidget {
  const TermsAndPrivacyText({super.key});

  @override
  Widget build(BuildContext context) {
    const String privacyPolicyUrl = 'https://quixotic-f1a0f.web.app/privacy';
    const String termsAndConditionsUrl = 'https://quixotic-f1a0f.web.app/terms';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            launchURL(Uri.parse(termsAndConditionsUrl));
          },
          child: const Text(
            'Terms of Use',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const Text(
          ' | ',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        InkWell(
          onTap: () {
            launchURL(Uri.parse(privacyPolicyUrl));
          },
          child: const Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
