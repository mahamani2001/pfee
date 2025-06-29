import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/shared/ui/input_field.dart';
import 'package:mypsy_app/shared/ui/loader/loader.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TextEditingController? _numbreExperienceController;
  String? _selectedValue, _selectedValuePsy;
  String? role;
  final Map<String, String> _displayToBackend = {
    'Lycéen(ne)': 'Lyceen(ne)',
    'Étudiant(e)': 'Etudiant(e)',
    'Employee': 'Employee',
    "En recherche d'emploi": "En recherche d'emploi",
  };
  final Map<String, String> _displayToBackendSpec = {
    'Psychiatrie sociale': 'Psychiatrie sociale',
    'Psychiatrie gériatrique': 'Psychiatrie gériatrique'
  };
  List<String> get _options => _displayToBackend.keys.toList();
  List<String> get _optionsSpecialite => _displayToBackendSpec.keys.toList();

  bool ispressed = false;
  final inputDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    fetchData();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController(text: "");
    _numbreExperienceController = TextEditingController();
  }

  Future<void> fetchData() async {
    final token = await AuthService().getJwtToken();
    final prefs = await SharedPreferences.getInstance();

    if (token == null) {
      customFlushbar("", "Session expirée", context, isError: true);
      return;
    }

    final url = Uri.parse('${AppConfig.instance()!.baseUrl!}auth/me');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['user'];
      final backendDateFormat = DateFormat('yyyy-MM-dd');

      setState(() {
        role = prefs.getString('user_role');
        _emailController?.text = data['email'] ?? '';
        _phoneController?.text = data['telephone'] ?? '';
        _numbreExperienceController?.text = data['experience'] ?? '';

        _selectedValue = _displayToBackend.keys.firstWhere(
          (key) => _displayToBackend[key] == (data['dans_la_vie_tu_es'] ?? ''),
          orElse: () => '',
        );
        _dobController?.text = data['date_of_birth'] != null
            ? inputDateFormat
                .format(backendDateFormat.parse(data['date_of_birth']))
            : '';

        final fullName = (data['full_name'] ?? '').trim().split(' ');
        if (fullName.length >= 2) {
          _lastNameController?.text = fullName[0];
          _firstNameController?.text = fullName.sublist(1).join(' ');
        } else if (fullName.length == 1) {
          _lastNameController?.text = fullName[0];
        }
      });
    } else {
      customFlushbar("", "Impossible de charger les infos", context,
          isError: true);
    }
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
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      String formattedDate = inputDateFormat.format(picked);
      setState(() {
        _dobController!.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mypsyBgApp,
        appBar: TopBarSubPage(title: widget.title),
        body: Stack(
          children: [
            SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/profile/${widget.iconName}.svg',
                            height: 22,
                            color: AppColors.mypsyPrimary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.title,
                            style: AppThemes.getTextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      formUi(),
                    ],
                  ),
                ),
              ),
            ),
            if (ispressed)
              Positioned.fill(
                child: Container(
                  color: AppColors.mypsyBlack.withOpacity(0.2),
                  child: const Center(child: mypsyLoader()),
                ),
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
              (_) => null,
              TextInputAction.done,
              onChanged: (_) => _formKey.currentState!.validate(),
              isRequired: false,
            ),
            const SizedBox(height: 11),
            InputField(
              _firstNameController,
              "Nom",
              (_) => null,
              TextInputAction.done,
              onChanged: (_) => _formKey.currentState!.validate(),
            ),
            const SizedBox(height: 11),
            InputField(
              _emailController,
              "E-mail",
              (value) {
                if (value!.isEmpty) return "Renseignez votre email";
                final pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                if (!RegExp(pattern).hasMatch(value)) {
                  return "Entrez une adresse mail valide";
                }
                return null;
              },
              TextInputAction.done,
              onChanged: (_) => _formKey.currentState!.validate(),
            ),
            const SizedBox(height: 11),
            InputField(
              _phoneController,
              "Téléphone",
              (value) => value!.isEmpty
                  ? "Renseignez votre numéro de téléphone"
                  : null,
              TextInputAction.done,
              onChanged: (_) => _formKey.currentState!.validate(),
            ),
            const SizedBox(height: 11),
            InputField(
              _dobController,
              "Date de naissance",
              (_) => null,
              TextInputAction.done,
              isReadOnly: true,
              onTap: () => _selectDate(context),
              isRequired: false,
              fromAuthentification: true,
            ),
            const SizedBox(height: 11),
            (role == PSY_ROLE) ? optionUiPsy() : optionUi(),
            const SizedBox(height: 15),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: mypsyButton(
                text: "Valider",
                onPress: () async {
                  if (_dobController!.text.isEmpty) {
                    customFlushbar("",
                        "Merci de renseigner votre date de naissance", context,
                        isError: true);
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    setState(() => ispressed = true);
                    await updateUserProfile();
                    setState(() => ispressed = false);
                  }
                },
              ),
            ),
          ],
        ),
      );
  Widget optionUiPsy() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Specialite", style: AppThemes.getTextStyle()),
          if (_optionsSpecialite.isNotEmpty)
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text(
                "Specialite",
                style: AppThemes.placeholderStyle,
              ),
              value: _optionsSpecialite.contains(_selectedValuePsy)
                  ? _selectedValuePsy
                  : null,
              onChanged: (value) {
                setState(() {
                  _selectedValuePsy = value;
                });
              },
              items: _optionsSpecialite
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, style: AppThemes.placeholderStyle),
                      ))
                  .toList(),
            ),
          InputField(
            _numbreExperienceController,
            "Experience",
            (value) =>
                value!.isEmpty ? "Renseignez votre numero d'experience" : null,
            TextInputAction.done,
            onChanged: (_) => _formKey.currentState!.validate(),
          ),
        ],
      );

  Widget optionUi() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dans la vie tu es ?", style: AppThemes.getTextStyle()),
          if (_options.isNotEmpty)
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text(
                "Dans la vie tu es ?",
                style: AppThemes.placeholderStyle,
              ),
              value: _selectedValue != null &&
                      _selectedValue!.isNotEmpty &&
                      _options.contains(_selectedValue)
                  ? _selectedValue
                  : null,
              onChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
              },
              items: _options
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, style: AppThemes.placeholderStyle),
                      ))
                  .toList(),
            ),
        ],
      );

  Future<void> updateUserProfile() async {
    final token = await AuthService().getJwtToken();

    if (token == null) {
      customFlushbar("", "Session expirée. Veuillez vous reconnecter.", context,
          isError: true);
      return;
    }

    final inputDateFormat = DateFormat('dd/MM/yyyy');
    final backendDateFormat = DateFormat('yyyy-MM-dd');

    if (_dobController!.text.trim().isEmpty) {
      customFlushbar("", "Date de naissance requise", context, isError: true);
      return;
    }

    late DateTime parsedDate;
    try {
      parsedDate = inputDateFormat.parse(_dobController!.text.trim());
    } catch (e) {
      customFlushbar("", "Format de date invalide", context, isError: true);
      return;
    }

    String formattedDate = backendDateFormat.format(parsedDate);

    final url = Uri.parse('${AppConfig.instance()!.baseUrl!}auth/editprofil');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "full_name":
            "${_lastNameController!.text.trim()} ${_firstNameController!.text.trim()}",
        "email": _emailController!.text.trim(),
        "telephone": _phoneController!.text.trim(),
        "date_de_naissance": formattedDate,
        "dans_la_vie_tu_es": role == PSY_ROLE
            ? _displayToBackendSpec[_selectedValuePsy]
            : _displayToBackend[_selectedValue],
        "role": role,
        "experience":
            role == PSY_ROLE ? _numbreExperienceController!.text.trim() : 0,
        "specialty": role == PSY_ROLE ? _selectedValuePsy ?? "" : null
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      customFlushbar("", "Mise à jour réussie", context);
      //
      await AuthService().getUserFullName();
    } else {
      customFlushbar("", data['message'] ?? 'Erreur serveur', context,
          isError: true);
    }
  }
}
