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
import 'package:mypsy_app/utils/functions.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  final Map<String, String> _displayToBackend = {
    'Lycéen(ne)': 'Lyceen(ne)',
    'Étudiant(e)': 'Etudiant(e)',
    'Employee': 'Employee',
    "En recherche d'emploi": "En recherche d'emploi",
  };

  List<String> get _options => _displayToBackend.keys.toList();

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
  }

  Future<void> fetchData() async {
    final token = await AuthService().getJwtToken();

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
        _emailController?.text = data['email'] ?? '';
        _phoneController?.text = data['telephone'] ?? '';
        _selectedValue = _displayToBackend.keys.firstWhere(
          (key) => _displayToBackend[key] == (data['dans_la_vie_tu_es'] ?? ''),
          orElse: () => '', // Default to empty if no match
        );
        _dobController?.text = data['date_of_birth'] != null
            ? inputDateFormat
                .format(backendDateFormat.parse(data['date_of_birth']))
            : '';

        // Extraire prénom et nom si besoin
        final fullName = (data['full_name'] ?? '').trim().split(' ');
        if (fullName.length >= 2) {
          _lastNameController?.text = fullName[0]; // prénom
          _firstNameController?.text = fullName.sublist(1).join(' '); // nom
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
            Text("Dans la vie tu es ?", style: AppThemes.getTextStyle()),
            if (_options
                .isNotEmpty) // Only show DropdownButton if options exist
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
                          child:
                              Text(option, style: AppThemes.placeholderStyle),
                        ))
                    .toList(),
              )
            else
              const Text("Aucune option disponible",
                  style: AppThemes.placeholderStyle),
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
        "dans_la_vie_tu_es": _displayToBackend[_selectedValue] ?? "",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      customFlushbar("", "Mise à jour réussie", context);
    } else {
      customFlushbar("", data['message'] ?? 'Erreur serveur', context,
          isError: true);
    }
  }
}
