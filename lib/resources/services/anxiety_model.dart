import 'package:tflite_flutter/tflite_flutter.dart';

class AnxietyModel {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    print("⏳ Tentative de chargement du modèle...");
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_anxiety.tflite');
      print("✅ Modèle TFLite chargé avec succès !");
    } catch (e) {
      print("❌ Erreur de chargement du modèle : $e");
      _interpreter = null;
    }
  }

  Future<int> predict(List<double> inputs) async {
    if (_interpreter == null) {
      throw Exception("❌ Le modèle n’a pas été chargé correctement !");
    }

    var input = [inputs];
    var output = List.filled(4, 0.0).reshape([1, 4]);

    _interpreter!.run(input, output);
    final List<double> result = List<double>.from(output[0]);
    final maxIndex =
        result.indexWhere((x) => x == result.reduce((a, b) => a > b ? a : b));
    return maxIndex;
  }
}
