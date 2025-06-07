import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/screens/layouts/main_layout.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/themes/top_ui.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/shared/ui/input_field.dart';
import 'package:mypsy_app/shared/ui/loader/loader.dart';
import 'package:mypsy_app/utils/functions.dart';

class Signup extends StatefulWidget {
  const Signup({
    super.key,
  });

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController? _emailController = TextEditingController();
  TextEditingController? _firstNameController = TextEditingController();
  TextEditingController? _lastNameController = TextEditingController();
  TextEditingController? _phoneController = TextEditingController();
  TextEditingController? _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePwd = true, ispressed = false;
  String? _selectedValue;
  bool hiddenPassword1 = true,
      clickedBtn = false,
      hiddenPassword2 = true,
      pwdLengthchk = true,
      pwdUppercheck = true,
      pwdSpclchk = true,
      pwdNumberCheck = true,
      pwdMatch = true,
      btnPressed = false,
      showPartTwo = false;
  Color color1 = AppColors.mypsyBgApp,
      color2 = AppColors.mypsyBgApp,
      color3 = AppColors.mypsyBgApp;
  final List<String> _options = [
    'Lycéen(ne)',
    'Étudiant(e)',
    'Employee',
    "En recherche d'emploi",
  ];

  final inputDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    ispressed = false;

    _passwordController.addListener(() {
      if (_passwordController.text.isEmpty) {
        setState(() {
          pwdLengthchk = false;
          pwdUppercheck = false;
          pwdSpclchk = false;
          pwdNumberCheck = false;
        });
      } else {
        //length check
        if (_passwordController.text.length >= 8) {
          setState(() {
            pwdLengthchk = true;
            color1 = AppColors.mypsyGreen;
          });
        } else if (_passwordController.text.isEmpty ||
            (_passwordController.text.isNotEmpty &&
                _passwordController.text.length < 8)) {
          setState(() {
            pwdLengthchk = false;
            color1 = AppColors.mypsyAlertRed;
          });
        }
//alteast one uppercase
        String patternUpper = '[A-Z]+';
        RegExp regExpUpper = new RegExp(patternUpper);
        if (regExpUpper.hasMatch(_passwordController.text) &&
            _passwordController.text.isNotEmpty) {
          setState(() {
            pwdUppercheck = true;
            color2 = AppColors.mypsyGreen;
          });
        } else {
          setState(() {
            pwdUppercheck = false;
            color2 = AppColors.mypsyAlertRed;
          });
        }
        //atleast one number, character or space

        //false means grey, true means green
        if (_passwordController.text.isNotEmpty) {
          if (regNum.hasMatch(_passwordController.text)) {
            setState(() {
              pwdNumberCheck = true;
              color3 = AppColors.mypsyGreen;
            });
          } else {
            setState(() {
              pwdNumberCheck = false;
              color3 = AppColors.mypsyAlertRed;
            });
          }
          if (pwdNumberCheck && regspcl.hasMatch(_passwordController.text)) {
            setState(() {
              pwdSpclchk = true;
              color3 = AppColors.mypsyGreen;
            });
          } else if (pwdNumberCheck &
              regSpace.hasMatch(_passwordController.text)) {
            setState(() {
              pwdSpclchk = true;
              color3 = AppColors.mypsyGreen;
            });
          } else {
            setState(() {
              pwdSpclchk = false;
              pwdNumberCheck = false;
              color3 = AppColors.mypsyAlertRed;
            });
          }
        }
      }
      if (pwdUppercheck) {
        setState(() {
          color2 = AppColors.mypsyGreen;
        });
      }
      if (pwdLengthchk) {
        setState(() {
          color1 = AppColors.mypsyGreen;
        });
      }
      if (pwdSpclchk && pwdNumberCheck) {
        setState(() {
          color3 = AppColors.mypsyGreen;
        });
      }
    });

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _dobController = TextEditingController(text: "");
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController!.dispose();
    _lastNameController!.dispose();
    _emailController!.dispose();
    _phoneController!.dispose();
    _dobController!.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      String formattedDate = inputDateFormat.format(picked);
      setState(() {
        //  _dobController.text = "${picked.toLocal()}".split(' ')[0];
        _dobController!.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top Curve
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: TopWaveClipper(),
                child: Container(
                  height: 180,
                  color: AppColors.mypsyPrimary,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.mypsyWhite),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Image.asset(
                            'assets/MYPsy.png',
                            height: 120,
                            width: 160,
                            color: AppColors.mypsyWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Vous avez déjà un compte ? Connectez-vous",
                  style: AppThemes.getTextStyle(
                      size: 13, clr: AppColors.mypsyBlack),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            Positioned.fill(
              top: 170,
              bottom: 80,
              child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: formUi()),
            ),
          ],
        ),
      );

  Widget formUi() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              _lastNameController,
              "Prénom",
              (value) {
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
              isRequired: false,
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              _firstNameController,
              "Nom",
              (value) {
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              _emailController,
              "E-mail",
              (value) {
                if (value!.isEmpty) {
                  return "Renseignez votre email";
                }
                String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                RegExp regExp = RegExp(emailPattern);
                if (!regExp.hasMatch(value)) {
                  return "Entrez une adresse mail valide";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              _phoneController,
              "Téléphone",
              (value) {
                if (value!.isEmpty) {
                  return "Renseignez votre numéro de téléphone";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              isReadOnly: true,
              onTap: () => _selectDate(context),
              hideTopLabel: false,
              _dobController,
              "Date de naissance",
              (value) {
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
              isRequired: false,
              fromAuthentification: true,
            ),
            const SizedBox(
              height: 11,
            ),
            InputField(
              hideTopLabel: false,
              _passwordController,
              showEyes: true,
              "Mot de passe",
              (value) {
                if (value!.isEmpty) {
                  return "Mot de passe requis";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) {
                _formKey.currentState!.validate();
              },
              fromAuthentification: true,
              hidePwd: _obscurePwd,
              withHideIcon: false,
              pressedIcon: () {
                setState(() {
                  _obscurePwd = !_obscurePwd;
                });
              },
            ),
            const SizedBox(
              height: 11,
            ),
            DropdownButton<String>(
              hint: Text(
                "Dans la vie tu es ?",
                style: AppThemes.getTextStyle(),
              ),
              isExpanded: true,
              value: _selectedValue != null
                  ? _selectedValue!.isNotEmpty
                      ? _selectedValue
                      : null
                  : null,
              onChanged: (newValue) {
                setState(() {
                  _selectedValue = newValue;
                });
              },
              items: _options
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: AppThemes.getTextStyle(),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: mypsyButton(
                onPress: () async {
                  if (_dobController!.text.isEmpty) {
                    customFlushbar("",
                        "Merci de renseigner votre date de naissance", context,
                        isError: true);
                  }
                  if (_formKey.currentState!.validate() &&
                      _dobController!.text.isNotEmpty) {
                    _formKey.currentState!.save();
                    setState(() {
                      ispressed = true;
                    });
                    // save USER
                    setState(() {
                      ispressed = false;
                    });
                    customFlushbar(
                      "",
                      "Mise à jour réussie",
                      context,
                    );
                  } else {
                    setState(() {
                      ispressed = false;
                    });
                    customFlushbar("", 'Erreur', context, isError: true);
                  }
                },
                text: "Valider",
              ),
            ),
          ],
        ),
      );
}
