import 'package:tflite_flutter/tflite_flutter.dart';

class AnxietyModel {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('anxiety_model.tflite');
  }

  Future<int> predict(List<double> inputs) async {
    var input = [inputs]; // shape [1, 7]
    var output = List.filled(4, 0.0).reshape([1, 4]);

    _interpreter.run(input, output);

    // Trouver l’index du score le plus élevé (softmax)
    final result = output[0];
    final maxIndex =
        result.indexWhere((x) => x == result.reduce((a, b) => a > b ? a : b));
    return maxIndex; // 0 = Minimal, 1 = Léger, etc.
  }
}
