import 'dart:io';
import 'package:mypsy_app/models/app_version.dart';
import 'package:mypsy_app/provider/api_provider.dart';
import 'package:mypsy_app/screens/authentification/login.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/device_types.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with TickerProviderStateMixin {
  AnimationController? _animationControllerFirstWord,
      _animationControllerSecondWord;
  AnimationController? _animationControllerFlare;
  AnimationController? _animationControllerLogo;
  late Animation<double> _animation;
  SharedPreferences? prefs;
  String? deviceId = '', userNameSavec = '', pwdSaved = '';
  bool finalWordsAnimationDone = false;
  final flareAnimationTime = const Duration(milliseconds: 1000);

  final data = ['K', 'L', 'U', 'B'];
  final data2 = ['K', 'L', 'U', 'B'];
  bool? stopSplash = false, showUpdateMessage, optionalUpdate, forceUpdate;
  @override
  void initState() {
    _animationControllerFirstWord = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ),
    );
    _animationControllerSecondWord = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationControllerFlare =
        AnimationController(vsync: this, duration: flareAnimationTime);
    _animationControllerLogo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationControllerFirstWord!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationControllerSecondWord!.forward();
      } else if (status == AnimationStatus.reverse) {
        _animationControllerSecondWord!.reverse();
      }
    });

    _animationControllerSecondWord!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          finalWordsAnimationDone = true;
        });
        _animationControllerFlare!.forward();
      } else if (status == AnimationStatus.reverse) {
        setState(() {
          finalWordsAnimationDone = false;
        });
        _animationControllerFlare!.reverse();
      }
    });

    _animationControllerFlare!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // redirect to home page
        _animationControllerFlare!.reverse();
        Provider.of<ApiProvider>(context, listen: false).initializeApi();
        Future.delayed(const Duration(milliseconds: 1000), () {
          endAndimation();
        });
      } else if (status == AnimationStatus.reverse) {
        _animationControllerLogo!.reverse();
      }
    });

    _animationControllerLogo!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationControllerFirstWord!.forward();
      } else if (status == AnimationStatus.reverse) {
        _animationControllerFirstWord!.reverse();
      }
    });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationControllerLogo!,
        curve: Curves.easeInOut,
      ),
    );

    _animationControllerLogo!.forward();

    super.initState();
  }

  void endAndimation() {
    checkForceUpdate(context).then((val) {
      setState(() {
        forceUpdate = val;
      });
      if (!val) {
        checkOptionalUpdate(context).then((value) async {
          setState(() {
            optionalUpdate = value;
            showUpdateMessage = optionalUpdate;
          });
          if (showUpdateMessage != null && showUpdateMessage == false) {
            checkLogin();
          }
        });
      } else {
        setState(() {
          showUpdateMessage = forceUpdate;
        });
      }
    });
  }

  Future<void> checkLogin() async {
    /*prefs = await SharedPreferences.getInstance();
    userNameSavec = await UserSecureStorage.getUsername();
    pwdSaved = await UserSecureStorage.getPwd();
    if (userNameSavec != null &&
        userNameSavec!.isNotEmpty &&
        pwdSaved != null &&
        pwdSaved!.isNotEmpty) {
      printConsole(
          "--- !!!! Yes it s already save it on the secure storage !!!");
      String? username = stringToBase64Url.decode(userNameSavec);
      String? password = stringToBase64Url.decode(pwdSaved);
      prefs!.setBool("appOnPause", true);
      //logged in
      deviceId = getDeviceId(prefs!);
      ProfileProvider authProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await authProvider.login(username!, password!);
      //logged in user
      if (authProvider.profileState == ProfileState.success) {
        prefs!.setBool('isLoggedIn', true);

        Provider.of<ApiProvider>(context, listen: false)
            .initializeApi(token: authProvider.token);
        mypsyApi api = mypsyApi();

        ProfileProvider profile =
            Provider.of<ProfileProvider>(context, listen: false);
        profile.setApi(api);
        UserRegister user = profile.user;
        await profile.getProfile(token: authProvider.token);
        await profile.getCitites();
        if (profile.profileState == ProfileState.success) {
          user = profile.user;
          print(" let s save the user ID ");
          prefs!.setInt("userId", user.id!);
          if (prefs!.getString("fcmToken") != null) {
            if (await profile.addDeviceToken(prefs!.getString("fcmToken")!,
                prefs!.getString("deviceType")!)) {
              print("------ END CALL PUSH NOTIFI API ");
            }
          }
        } 
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(
              initialTabIndex: 1,
            ),
          ),
        );
      } else {
        prefs!.setBool('isLoggedIn', false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
    } else {
      prefs!.setBool('isLoggedIn', false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
    }*/
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  @override
  void dispose() {
    _animationControllerFirstWord!.dispose();
    _animationControllerSecondWord!.dispose();
    _animationControllerFlare!.dispose();
    _animationControllerLogo!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mypsyPrimary,
        body: Stack(
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: FittedBox(
                child: Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        FadeTransition(
                          opacity: _animation,
                          child: Image.asset(
                            'assets/MYPsy.png',
                            width: 170.0,
                            height: 170.0,
                            color: AppColors.mypsyWhite,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: getChallengesWords(),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                    getLensFlareAnimation(),
                  ],
                ),
              ),
            ),
            if (showUpdateMessage != null && showUpdateMessage!)
              showForceUpdate(),
          ],
        ),
      );

  AnimatedBuilder getLensFlareAnimation() => AnimatedBuilder(
        animation: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationControllerFlare!,
            curve: Curves.elasticInOut,
          ),
        ),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              stops: [0.1, 0.9],
              colors: [
                Color.fromRGBO(250, 250, 250, 1),
                Color.fromRGBO(250, 250, 250, 0.1),
              ],
            ),
          ),
        ),
        builder: (BuildContext context, Widget? child) => AnimatedPositioned(
          top: 0,
          bottom: 0,
          left: _animationControllerFlare!.value > 0
              ? MediaQuery.of(context).size.width
              : -MediaQuery.of(context).size.width,
          duration: flareAnimationTime,
          child: child!,
        ),
      );

  List<Widget> getChallengesWords() {
    final List<Widget> challengeswords = [];
    for (int i = 0; i < data.length; i++) {
      challengeswords.add(
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationControllerFirstWord!,
            curve: const Interval(0, 1, curve: Curves.fastOutSlowIn),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationControllerFirstWord!,
                curve: Interval(
                  0 + i.toDouble() / 10,
                  1,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
            ),
            child: Text(
              data[i],
              style: const TextStyle(
                color: AppColors.mypsyPrimary,
                fontSize: 50,
                fontFamily: AppThemes.fontInter,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return challengeswords;
  }

  Widget showForceUpdate() => Stack(
        children: <Widget>[
          Container(
            color: AppColors.mypsyBlack.withOpacity(0.8),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 3.5,
            left: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 300,
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 25,
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 150,
                    ),
                    width: Device.get().isPhone!
                        ? MediaQuery.of(context).size.width - 100
                        : MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                      color: AppColors.mypsyWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Image.asset(
                          'assets/logo.png',
                          height: 40.0,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        const Text(
                          'Une nouvelle version de votre application est disponible, veuillez la mettre à jour !',
                          style: TextStyle(
                            color: AppColors.mypsyBlack,
                            fontWeight: FontWeight.normal,
                            fontFamily: AppThemes.fontInter,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (Device.get().isIos! || Platform.isIOS) {
                              launchLink('');
                            } else {
                              launchLink('');
                            }
                          },
                          child: btnUi('Mettre à jour', AppColors.mypsyPrimary),
                        ),
                        const SizedBox(
                          height: 11,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showUpdateMessage = false;
                              if (forceUpdate != null && forceUpdate!) {
                                exit(0);
                              } else {
                                checkLogin();
                              }
                            });
                          },
                          child: btnUi(
                            (optionalUpdate != null && optionalUpdate!)
                                ? 'Ignorer'
                                : "Fermer l'application",
                            AppColors.mypsySecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget btnUi(String txt, Color bgColor) => Container(
        alignment: Alignment.center,
        width: Device.get().isPhone!
            ? MediaQuery.of(context).size.width / 2.5
            : MediaQuery.of(context).size.width / 3,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          txt,
          style: const TextStyle(
            color: AppColors.mypsyWhite,
            fontWeight: FontWeight.normal,
            height: 1.2,
          ),
        ),
      );
}
