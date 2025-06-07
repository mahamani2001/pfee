import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/authentification/otp_screen.dart';
import 'package:mypsy_app/screens/authentification/widgets/footer_btn.dart';
import 'package:mypsy_app/screens/layouts/main_layout.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/shared/ui/input_field.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({
    super.key,
  });
  @override
  // ignore: library_private_types_in_public_api
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: "test@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "MAHAmani180801");
  bool _obscurePwd = true, ispressed = false;
  String customerID = '';
  bool showError = false;
  String phoneNumber = '';
  bool hiddenPassword1 = true, clickedBtn = false, btnPressed = false;

  SharedPreferences? prefs;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainLayout(
        title: '',
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: mainDecoration,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          child: Image.asset(
                            'assets/MYPsy.png',
                            height: 220,
                            width: 300,
                            color: AppColors.mypsyWhite,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'Bienvenue @ MyPsy',
                            style: AppThemes.headerStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        formUi(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: FooterLink(
                    onPress: () {},
                    text: 'Besoin d’aide ? Contactez l’assistance',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget formUi() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              _emailController,
              'Identifiant',
              (value) {
                if (value!.isEmpty) {
                  return 'Renseignez votre e-mail';
                } else {
                  Pattern pattern =
                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                  RegExp regex = RegExp(pattern as String);
                  RegExp regNumber = RegExp(r'^\+?[0-9]+$');
                  if (!regex.hasMatch(value) && (!regNumber.hasMatch(value))) {
                    return 'Entrez une adresse mail valide';
                  } else {
                    return null;
                  }
                }
              },
              TextInputAction.done,
              onChanged: (_) {
                //  _formKey.currentState!.validate();
              },
              fromAuthentification: true,
              isLightTheme: false,
            ),
            spaceBetweenInput,
            InputField(
              isLightTheme: false,
              _passwordController,
              'Mot de passe',
              (value) {
                if (value!.isEmpty) {
                  return 'Mot de passe requis';
                } else {
                  return null;
                }
              },
              TextInputAction.done,
              onChanged: (_) {
                //    _formKey.currentState!.validate();
              },
              fromAuthentification: true,
              hidePwd: _obscurePwd,
              withHideIcon: false,
              showEyes: true,
              pressedIcon: () {
                setState(() {
                  _obscurePwd = !_obscurePwd;
                });
              },
            ),
            spaceBetweenInput,
            Container(
              margin: const EdgeInsets.only(bottom: 35),
              child: Center(
                child: InkWell(
                  onTap: () {},
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: AppThemes.questionInfo,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: mypsyButton(
                onPress: ispressed ? null : _submitForm,
                bgColors: AppColors.mypsyPurple,
                text: 'Se connecter',
                withLoader: ispressed,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: mypsyButton(
                colr: AppColors.mypsyPurple,
                bgColors: AppColors.mypsyBgApp,
                onPress: _submitForm,
                text: 'Creer mon compte',
              ),
            ),
          ],
        ),
      );

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => ispressed = true);
    final authService = AuthService();
    print('Submit form ');
    final result = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    print('Submit form ');

    if (result['status'] == 200 && result['data']['twoFactorRequired']) {
      final tempToken = result['data']['tempToken'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(tempToken: tempToken),
        ),
      );

      setState(() => ispressed = false);
    } else {
      setState(() {
        ispressed = false;
      });
      customFlushbar('', 'Email/Mot de passe incorrecte', context,
          isError: true);
    }
  }
}
