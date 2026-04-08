import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'gemma_model_service.dart';
import 'nutrition_tools_schema.dart';

class FoodAnalysisResult {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String servingSize;

  FoodAnalysisResult({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.servingSize,
  });
}

class NutritionService {
  final GemmaModelService _gemmaModelService;

  NutritionService(this._gemmaModelService);

  Future<FoodAnalysisResult?> analyzeFood(Uint8List imageBytes) async {
    final systemInstruction = NutritionToolsSchema.getSystemInstruction();
    final prompt = NutritionToolsSchema.buildPrompt();

    final response = await _gemmaModelService.infer(
      prompt,
      systemInstruction: systemInstruction,
      imageBytes: imageBytes,
    );

    if (response.isEmpty) return null;

    // Extract JSON from response
    final firstBrace = response.indexOf('{');
    if (firstBrace == -1) return null;

    int depth = 0;
    int lastBrace = -1;
    for (int i = firstBrace; i < response.length; i++) {
      if (response[i] == '{') depth++;
      if (response[i] == '}') {
        depth--;
        if (depth == 0) {
          lastBrace = i;
          break;
        }
      }
    }
    if (lastBrace == -1) return null;

    final jsonStr = response.substring(firstBrace, lastBrace + 1);
    final Map<String, dynamic> json = jsonDecode(jsonStr);

    return FoodAnalysisResult(
      name: json['name'] as String? ?? 'Unknown food',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      servingSize: json['serving_size'] as String? ?? '1 serving',
    );
  }
}
