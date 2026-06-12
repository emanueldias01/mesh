import 'package:flutter/material.dart';
import 'package:mesh/ui/colors.dart';
import 'package:mesh/ui/text_styles.dart';
import 'package:mesh/widgets/principal_button.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 80,
              bottom: 40,
            ),
            child: Image.asset("assets/images/logo.png")
          ),

            Text("Start Meeting with any people", 
              style: AppTextStyles.mediumText
            ),

            SizedBox(height: 10),

            Text(
              "Right Now!",
              style: AppTextStyles.bigText.copyWith(color: AppColors.textPrimary)
            ),

            SizedBox(height: 250),

            PrincipalButton(
              text: "Get Started",
              onTap: () => Navigator.pushNamed(context, "/meeting_lobby"),
            )
            
        ],
      ),
    );
  }
}