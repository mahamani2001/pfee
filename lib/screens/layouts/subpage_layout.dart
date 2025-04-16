import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

class LayoutSubPage extends StatelessWidget {
  final Widget child;
  final String title;
  final bool withPadding;
  final bool withVerticalPadding;
  const LayoutSubPage(
      {super.key,
      required this.child,
      required this.title,
      this.withPadding = false,
      this.withVerticalPadding = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mypsyWhite,
        appBar: TopBarSubPage(title: title),
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: withPadding ? 16 : 0,
                vertical: withVerticalPadding ? 27 : 0,
              ),
              child: child),
        ),
      );
}
