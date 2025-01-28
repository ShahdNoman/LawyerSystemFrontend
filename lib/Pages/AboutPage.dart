import 'package:flutter/material.dart';

const Color primaryColor = Color.fromARGB(255, 1, 25, 65);
const Color textPrimaryColor = Color.fromARGB(255, 1, 25, 65);
const Color secondaryColor = Color(0xFF2a609e);
const Color lightTextColor = Colors.white70;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget gradientText(String text, {double fontSize = 22}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [secondaryColor, primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget section({
    required IconData icon,
    required String title,
    required String content,
    bool animateIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (animateIcon)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: Icon(icon, color: secondaryColor, size: 28),
                  );
                },
              )
            else
              Icon(icon, color: secondaryColor, size: 28),
            const SizedBox(width: 8),
            gradientText(title, fontSize: 24),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: textPrimaryColor.withOpacity(0.85),
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'About This App',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_animation.value, 0),
                      child: gradientText(
                        'JustiPro',
                        fontSize: 28,
                      ),
                    );
                  },
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: secondaryColor,
                  child: const Icon(Icons.gavel, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 18,
                color: textPrimaryColor.withOpacity(0.7),
                decoration: TextDecoration.underline,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 32),
            section(
              icon: Icons.info_outline,
              title: 'About Our App',
              content:
                  'This application is a Lawyer System designed to help lawyers and legal professionals manage their practice efficiently.\n\n'
                  '- Client management\n'
                  '- Case management\n'
                  '- Reporting\n'
                  '- Chat functionalities\n'
                  '- Administrative profile settings\n\n'
                  'We strive to provide an intuitive and reliable platform to enhance your legal practice.',
              animateIcon: true,
            ),
            section(
              icon: Icons.contact_support,
              title: 'Contact Us',
              content:
                  'For any inquiries or support, please reach out to justipro@gmail.com.',
              animateIcon: true,
            ),
            section(
              icon: Icons.developer_mode,
              title: 'Developed by',
              content: '',
              animateIcon: true,
            ),
            Column(
              children: [
                developerInfo('Shahd Hamad', 'sh.3182002@gmail.com'),
                developerInfo('Raia Ishtaya', 'raiaishtaya@gmail.com'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget developerInfo(String name, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, color: secondaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Add email tap functionality if needed
                  },
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
