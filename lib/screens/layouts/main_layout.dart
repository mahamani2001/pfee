import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/ui/loader/loader_page.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final bool withBack;
  final bool withBottom;
  final bool withTop;
  final String title;
  final bool showLoaderPage;
  final bool goToMainPage;
  final bool fromMemebr;
  final Widget? alert;
  final bool withBg;
  final bool withPasser;
  final bool fromSubPage;
  final bool showMention;
  final Function? goBackFct;

  const MainLayout({
    super.key,
    required this.child,
    this.withBack = false,
    this.withBottom = true,
    this.withTop = true,
    required this.title,
    this.showLoaderPage = false,
    this.goToMainPage = false,
    this.fromMemebr = false,
    this.alert,
    this.withBg = false,
    this.withPasser = false,
    this.fromSubPage = false,
    this.showMention = true,
    this.goBackFct,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.mypsyPrimary,
        body: SizedBox(
          height: size.height,
          width: size.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (withBg)
                Positioned.fill(
                  child: Image.asset(
                    'assets/bg-banner.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              if (withBack)
                Positioned(
                  top: 75,
                  left: 10,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.mypsyPrimary,
                        size: 22,
                      ),
                    ),
                    onPressed: () {
                      if (goBackFct != null) {
                        goBackFct!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              child,
              if (showLoaderPage)
                Container(
                  color: AppColors.mypsyBgApp.withOpacity(0.2),
                  child: const Center(child: LoaderPage()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
