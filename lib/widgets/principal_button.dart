import 'package:flutter/material.dart';
import 'package:mesh/ui/colors.dart';
import 'package:mesh/ui/text_styles.dart';

class PrincipalButton extends StatefulWidget {

  final String text;
  final VoidCallback onTap;

  const PrincipalButton({
    super.key,
    required this.text,
    required this.onTap
  });

  @override
  State<PrincipalButton> createState() => _PrincipalButtonState();
}


class _PrincipalButtonState extends State<PrincipalButton> {

  bool pressed = false;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },

      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },

      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },


      child: AnimatedScale(
        scale: pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),

          height: 50,
          width: 200,

          alignment: Alignment.center,

          decoration: BoxDecoration(

            gradient: LinearGradient(
              colors: pressed
                  ? [
                      AppColors.surface,
                      AppColors.surfaceVariant
                    ]
                  : [
                      AppColors.primary,
                      AppColors.primaryDark
                    ],
            ),

            borderRadius: BorderRadius.circular(50),


            boxShadow: pressed
                ? []
                : [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 5),
                      color: AppColors.primary.withOpacity(0.3),
                    )
                  ],
          ),

          child: Text(
            widget.text,
            style: AppTextStyles.mediumText.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}