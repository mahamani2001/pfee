import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/authentification/login.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/profil/contact.dart';
import 'package:mypsy_app/screens/profil/reglement.dart';
import 'package:mypsy_app/screens/profil/update_profile.dart';
import 'package:mypsy_app/screens/profil/update_pwd.dart';
import 'package:mypsy_app/screens/profil/widgets/item_menu.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/alert.dart';
import 'package:mypsy_app/shared/ui/loader/loader_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List myAccountMenu = [
  ["Éditer mon profil", "user-pen", "profile"],
  ["Éditer mon mot de passe", "user-pen", "mdp"],
  ["Aide", "question", "faqUrl"]
];

final List othersMenu = [
  ["Conditions générales", "conditionGeneraleUrl"],
  ["Politique de confidentialité", "politiqueUrl"],
  ["Déconnexion", "logout"]
];

class Settings extends StatefulWidget {
  const Settings({
    super.key,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool showPopup = false,
      showPopupSuppression = false,
      isDisconnected = false,
      isDeleteAccount = false,
      isChangeCity = false;
  SharedPreferences? prefs;
  @override
  void initState() {
    showPopup = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.mypsyBgApp,
            appBar: const TopBarSubPage(
              title: "Paramètres",
              goHome: true,
            ),
            body: SafeArea(
                child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      topTitle("Mon compte"),
                      const SizedBox(
                        height: 11,
                      ),
                      listMenu(myAccountMenu, true),
                      const SizedBox(
                        height: 5,
                      ),
                      topTitle("Autres"),
                      const SizedBox(
                        height: 11,
                      ),
                      listMenu(othersMenu, false),
                      const SizedBox(
                        height: 30,
                      ),
                    ]),
              ),
            )),
          ),
          if (showPopup)
            Positioned.fill(
              child: Container(
                color: AppColors.mypsyPlaceholderColor.withOpacity(0.5),
                child: alertUi(),
              ),
            ),
          if (isDisconnected) const LoaderPage()
        ],
      );

  Widget alertUi() => AlertYesNo(
        title: "Déconnexion ?",
        description: "Etes-vous sûr, voulez-vous vous déconnecter ?",
        btnTitle: "Oui",
        btnNoTitle: "Non",
        onClosePopup: () {
          setState(() {
            showPopup = false;
          });
        },
        onPressYes: () {
          setState(() {
            isDisconnected = true;
          });
          submitLogout();
          setState(() {
            isDisconnected = false;
          });
        },
      );

  Widget listMenu(List items, bool withIcon) {
    List<Widget> listWidgets = [];
    for (var index = 0; index < items.length; index++) {
      String url = withIcon ? items[index][2] : items[index][1];
      listWidgets.add(GestureDetector(
        onTap: url.isNotEmpty
            ? () {
                if (url.contains("profile") || url.contains('mdp')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => url.contains("profile")
                          ? UpdateProfile(
                              title: items[index][0],
                              iconName: items[index][1],
                              // user: widget.user,
                            )
                          : UpdatePwd(
                              title: items[index][0],
                              iconName: items[index][1],
                              //   user: widget.user,
                            ),
                    ),
                  );
                } else if (url.contains('faqUrl')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContactPage()),
                  );
                } else if (url.contains("logout")) {
                  // Deconnexion
                  setState(() {
                    showPopup = true;
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Reglement(
                          title: items[index][0], description: "Contenu ici"),
                    ),
                  );
                }
              }
            : null,
        child: ItemMenu(
            title: withIcon ? items[index][0] : items[index][0],
            iconName: withIcon ? items[index][1] : '',
            withColor: !withIcon && index == items.length - 1 ? true : false),
      ));
    }
    return Wrap(
      children: listWidgets,
    );
  }

  Widget topTitle(String text) => Text(
        text,
        style: AppThemes.getTextStyle(fontWeight: FontWeight.bold),
      );

  submitLogout() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }
}
