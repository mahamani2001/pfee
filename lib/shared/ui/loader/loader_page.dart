import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/ui/loader/loader.dart';
import 'package:flutter/material.dart';

class LoaderPage extends StatelessWidget {
  const LoaderPage({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: Center(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: AppColors.mypsyBlack.withOpacity(0.3),
            child: const Center(child: mypsyLoader()),
          ),
        ),
      );
}
