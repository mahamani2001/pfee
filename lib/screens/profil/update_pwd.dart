import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/shared/ui/input_field.dart';
import 'package:mypsy_app/shared/ui/loader/loader.dart';

class UpdatePwd extends StatefulWidget {
  final String title;
  final String iconName;
  //final UserRegister user;
  const UpdatePwd(
      {super.key,
      // required this.user,
      required this.title,
      required this.iconName});

  @override
  State<UpdatePwd> createState() => _UpdatePwdState();
}

class _UpdatePwdState extends State<UpdatePwd> {
  final GlobalKey<FormState> _formKeyPwd = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPwd = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePwd = true,
      _obscureCurrentPwd = true,
      _obscureConfirmPwd = true,
      ispressed = false;

  @override
  void initState() {
    ispressed = false;
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.mypsyBgApp,
      appBar: TopBarSubPage(
        title: widget.title,
      ),
      body: Stack(
        children: [
          SafeArea(
              child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/profile/${widget.iconName}.svg',
                          height: 22,
                          color: AppColors.mypsyPrimary,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          widget.title,
                          style: AppThemes.getTextStyle(
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    formUi(),
                  ]),
            ),
          )),
          if (ispressed)
            Positioned(
              child: Container(
                  color: AppColors.mypsyBlack.withOpacity(0.2),
                  child: const Center(child: mypsyLoader())),
            ),
        ],
      ));

  Widget formUi() => Form(
        key: _formKeyPwd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              _currentPwd,
              "Mot de passe actuel",
              (value) {
                if (value!.isEmpty) {
                  return "Vous devez indiquer votre ancien mot de passe";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKeyPwd.currentState!.validate();
              },
              hidePwd: _obscureCurrentPwd,
              withHideIcon: false,
              pressedIcon: () {
                setState(() {
                  _obscureCurrentPwd = !_obscureCurrentPwd;
                });
              },
              showEyes: true,
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              _passwordController,
              "Nouveau mot de passe",
              (value) {
                if (value.isEmpty) {
                  return "Vous devez indiquer votre nouveau mot de passe";
                } else if (value == _currentPwd.text) {
                  return "L'ancien et le nouveau mot de passe ne peuvent pas être  identiques";
                } else {
                  return null;
                }
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKeyPwd.currentState!.validate();
              },
              hidePwd: _obscurePwd,
              withHideIcon: false,
              pressedIcon: () {
                setState(() {
                  _obscurePwd = !_obscurePwd;
                });
              },
              showEyes: true,
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              _confirmPasswordController,
              "Confirmer le mot de passe",
              (value) {
                if (value!.isEmpty) {
                  return "Vous devez confirmer votre nouveau mot de passe";
                }
                if (value != _passwordController.text) {
                  return "Les nouveaux mots de passe doivent correspondre";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKeyPwd.currentState!.validate();
              },
              showEyes: true,
              hidePwd: _obscureConfirmPwd,
              withHideIcon: false,
              pressedIcon: () {
                setState(() {
                  _obscureConfirmPwd = !_obscureConfirmPwd;
                });
              },
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: mypsyButton(
                onPress: _submitForm,
                text: "Valider",
              ),
            ),
          ],
        ),
      );

  _submitForm() async {
    if (_formKeyPwd.currentState!.validate()) {
      setState(() => ispressed = true);
      final token = await AuthService().getJwtToken();

      final url =
          Uri.parse('${AppConfig.instance()!.baseUrl!}auth/updatePassword');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "currentPassword": _currentPwd.text.trim(),
          "newPassword": _passwordController.text.trim(),
          "confirmPassword": _confirmPasswordController.text.trim(),
        }),
      );

      setState(() => ispressed = false);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        customFlushbar("", data['message'], context);
        clearForm();
      } else {
        customFlushbar("", data['message'], context, isError: true);
      }
    } else {
      customFlushbar("", "Erreur lors de l'envoi", context, isError: true);
    }
  }

  void clearForm() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _currentPwd.clear();
  }
}
