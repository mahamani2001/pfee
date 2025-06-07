import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/shared/ui/input_field.dart';
import 'package:mypsy_app/shared/ui/loader/loader.dart';
import 'package:mypsy_app/utils/functions.dart';

class UpdateProfile extends StatefulWidget {
  final String title;
  final String iconName;

  const UpdateProfile({
    super.key,
    required this.title,
    required this.iconName,
  });

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController? _emailController;
  TextEditingController? _firstNameController;
  TextEditingController? _lastNameController;
  TextEditingController? _phoneController;
  TextEditingController? _dobController;
  String? _selectedValue;

  final List<String> _options = [
    'Lycéen(ne)',
    'Étudiant(e)',
    'Employee',
    "En recherche d'emploi",
  ];

  bool ispressed = false;

  Future fetchData() async {
    //Get user heree !!
  }

  final inputDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    fetchData();
    ispressed = false;
    /* _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    if (widget.user.activity != null) {
      _selectedValue = widget.user.activity;
    }
    _dobController = TextEditingController(
        text: widget.user.dateOfBirth != null
            ? getDateFromApi(widget.user.dateOfBirth!)
            : "");*/
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
            Text(
              "Dans la vie tu es ?",
              style: AppThemes.getTextStyle(),
            ),
            DropdownButton<String>(
              hint: const Text(
                "Dans la vie tu es ?",
                style: AppThemes.placeholderStyle,
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
                          style: AppThemes.placeholderStyle,
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
