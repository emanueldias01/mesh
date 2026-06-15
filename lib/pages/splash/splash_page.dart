import 'package:flutter/material.dart';
import 'package:mesh/ui/colors.dart';
import 'package:mesh/ui/text_styles.dart';
import 'package:mesh/widgets/principal_button.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),

                      Image.asset(
                        "assets/images/logo.png",
                        width: isDesktop
                            ? 300
                            : constraints.maxWidth * 0.5,
                      ),

                      const SizedBox(height: 40),

                      Text(
                        "Start Meeting with any people",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.mediumText,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Right Now!",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bigText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: PrincipalButton(
                          text: "Get Started",
                          onTap: () => Navigator.pushNamed(
                            context,
                            "/meeting_lobby",
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}