import 'package:mypsy_app/screens/layouts/top_bar.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

class LayoutPage extends StatelessWidget {
  final Widget child;
  final String title;
  final bool withPadding;
  final bool withVerticalPadding;
  const LayoutPage(
      {super.key,
      required this.child,
      required this.title,
      this.withPadding = false,
      this.withVerticalPadding = true});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.mypsyWhite,
      appBar: TopBarMainPage(
        title: title,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: child),
      ));
}
