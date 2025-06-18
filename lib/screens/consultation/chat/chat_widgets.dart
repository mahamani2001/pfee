import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:mypsy_app/utils/functions.dart';
import 'package:url_launcher/url_launcher.dart';

Widget headerInfo(bool isPeerOnline, String peerName, String id) => Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/images/doctor_avatar.png'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerName + id,
                  style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyWhite, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPeerOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPeerOnline ? "En ligne" : "Hors ligne",
                    style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyWhite,
                      size: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );

Widget msgRead(bool fromMe, String msg, {String status = 'sent'}) => Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(msg, style: const TextStyle(fontSize: 16))),
            if (fromMe) ...[
              const SizedBox(width: 6),
              Icon(
                status == 'sent' ? Icons.done_all : Icons.done,
                size: 18,
                color: status == 'sent' ? Colors.blue : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );

Widget endChat() => Center(
      child: Text("⏰ La consultation est terminée",
          style:
              AppThemes.getTextStyle(clr: AppColors.mypsyAlertRed, size: 18)),
    );

Widget userTypingText(String peerName) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          "$peerName est en train d’écrire...",
          style:
              const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ),
    );

Widget buildAudioBubble(String filePath, bool fromMe) =>
    FutureBuilder<Duration?>(
      future: getAudioDuration(filePath),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final durationFormatted = formatDurationSeconds(duration.inSeconds);

        return Align(
          alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fromMe ? const Color(0xFF128C7E) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow,
                      color: fromMe ? Colors.white : Colors.black87),
                  onPressed: () => _playAudioWithJustAudio(filePath, context),
                ),
                const SizedBox(width: 4),
                Text(
                  durationFormatted,
                  style: TextStyle(
                    color: fromMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

Widget buildPdfBubble(String fileName, String filePath, bool fromMe) => Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fromMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 28, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? 'Document',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () {
                _openFile(filePath);
              },
            ),
          ],
        ),
      ),
    );

Widget buildVocalMessage(bool fromMe, String fileName, Function onTap) => Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow, color: Colors.black),
              SizedBox(width: 8),
              Text('Écouter le message'),
            ],
          ),
        ),
      ),
    );

Widget buildImageBubble(String filePath, bool fromMe) {
  final isUrl = filePath.startsWith('http');

  return Align(
    alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      clipBehavior: Clip.hardEdge,
      child: isUrl
          ? Image.network(
              filePath,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            )
          : Image.file(
              File(filePath),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
    ),
  );
}

Future<void> _playAudioWithJustAudio(
    String filePath, BuildContext context) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print("❌ Fichier audio introuvable : $filePath");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fichier audio introuvable")),
    );
    return;
  }

  final player = AudioPlayer();

  try {
    await player.setFilePath(filePath);
    await player.play();
    print("🎧 Lecture en cours...");
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        print("✅ Lecture terminée");
        player.dispose(); // Libère les ressources
      }
    });
  } catch (e) {
    print("❌ Erreur pendant la lecture : $e");
  }
}

Future<Duration?> getAudioDuration(String filePath) async {
  try {
    final player = AudioPlayer();
    await player.setFilePath(filePath); // ❌ ne joue rien, juste charge
    final duration = player.duration;
    await player.dispose(); // libère les ressources
    return duration;
  } catch (e) {
    print("❌ Erreur de durée audio : $e");
    return null;
  }
}

void _openFile(String filePath) async {
  try {
    if (filePath.startsWith('http')) {
      final encoded = Uri.encodeFull(filePath);
      final uri = Uri.parse(encoded);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Impossible d’ouvrir le lien dans une app... essai navigateur');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } else {
      // ✅ ouvrir localement si c'est un fichier
      await OpenFile.open(filePath);
    }
  } catch (e) {
    print("❌ Impossible d’ouvrir le fichier : $e");
  }
}
