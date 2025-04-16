import 'package:mypsy_app/screens/layouts/page_layout.dart';
import 'package:mypsy_app/screens/profil/widgets/hotline_info.dart';
import 'package:mypsy_app/screens/profil/widgets/hotline_inquiry.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:mypsy_app/utils/constants.dart';
import 'package:mypsy_app/utils/functions.dart';
import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutPage(
        title: 'Profil',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionTitle(
              'Mes coordonnées',
            ),
            spacerSubTitle,
            buildSectionInfo('Civilité', 'M.'),
            spacerSubTitle,
            buildSectionInfo('Prénom / Nom', 'Mani Maha'),
            spacerSubTitle,
            buildSectionInfo('E-mail', 'abm@atmosphairconcept.fr'),
            spacerSubTitle,
            buildSectionInfo('Téléphone fixe', '-'),
            spacerSubTitle,
            buildSectionInfo('Téléphone mobile', '-'),
            buildDivider(),
            buildSectionTitle('À propos de MYPsy'),
            buildMenuItem('Besoin d’aide sur MYPsy ?', () {
              Navigator.pushNamed(context, Routes.contact);
            }),
            buildMenuItem('Quiz', () {
              Navigator.pushNamed(context, Routes.contact);
            }),
            buildExternalLink('Règlement  ', urlReglemnt),
            buildMenuItem('Mentions légales', () {}),
          ],
        ),
      );

  Widget buildDivider() => Padding(
        padding: const EdgeInsets.only(top: 5.0, bottom: 22),
        child:
            Divider(thickness: 1, color: AppColors.mypsyGrey.withOpacity(0.15)),
      );

  Widget buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 17.0),
        child: Text(title, style: AppThemes.titleStylePrimary),
      );

  Widget buildMenuItem(String title, VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: itemMenu(title));

  Widget buildExternalLink(String title, String url) => GestureDetector(
        onTap: () {
          launchLink(url);
        },
        child: itemMenu(title, isExternal: true),
      );

  Widget itemMenu(String title, {bool isExternal = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 17.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppThemes.subMenuStyle,
            ),
            Icon(
              isExternal ? Icons.open_in_new : Icons.chevron_right,
              color: AppColors.mypsyIconGrey,
            ),
          ],
        ),
      );
}

Widget buildSectionTitle(String title) => Text(
      title,
      style: AppThemes.getTextStyle(
        size: 16,
        fontWeight: FontWeight.w600,
      ),
    );

Widget buildSectionInfo(String title, String subTitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppThemes.getTextStyle(size: 13)),
        Text(subTitle,
            style: AppThemes.getTextStyle(
                size: 13, clr: AppColors.mypsyBlack.withOpacity(0.35))),
      ],
    );

Widget buildListBenefits(context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width - 60,
            height: 200,
            child: const HotlineInfo(),
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 60,
            child: const HotlineInquiry(),
          ),
        ],
      ),
    );
