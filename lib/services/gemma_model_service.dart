import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gemma_models.dart';
import 'voice_command_service.dart';

class DownloadProgress {
  final double downloadedMB;
  final double totalMB;
  final double speedMBps;
  final double percent;

  DownloadProgress({
    required this.downloadedMB,
    required this.totalMB,
    required this.speedMBps,
    required this.percent,
  });
}

class GemmaModelStateNotifier extends StateNotifier<Map<String, GemmaModelState>> {
  GemmaModelStateNotifier() : super({
    for (var model in GemmaModels.availableModels) model.id: GemmaModelState.notDownloaded
  });

  void updateState(String modelId, GemmaModelState state) {
    this.state = {...this.state, modelId: state};
  }

  void setActive(String modelId) {
    final newState = Map<String, GemmaModelState>.from(state);
    // Deactivate currently active
    newState.forEach((key, value) {
      if (value == GemmaModelState.active) {
        newState[key] = GemmaModelState.downloaded;
      }
    });
    newState[modelId] = GemmaModelState.active;
    this.state = newState;
  }
}

final gemmaModelStateProvider = StateNotifierProvider<GemmaModelStateNotifier, Map<String, GemmaModelState>>((ref) {
  return GemmaModelStateNotifier();
});

final activeGemmaModelProvider = Provider<GemmaModelConfig?>((ref) {
  final states = ref.watch(gemmaModelStateProvider);
  final activeId = states.entries.firstWhere((e) => e.value == GemmaModelState.active, orElse: () => const MapEntry("", GemmaModelState.notDownloaded)).key;
  if (activeId.isEmpty) return null;
  return GemmaModels.availableModels.firstWhere((m) => m.id == activeId);
});

class GemmaModelService {
  static const MethodChannel _channel = MethodChannel('com.gymtrack.gemma_litert');
  static const EventChannel _progressChannel = EventChannel('com.gymtrack.gemma_litert_progress');
  static const EventChannel _streamChannel = EventChannel('com.gymtrack.gemma_litert_stream');
  
  final Ref ref;
  
  GemmaModelService(this.ref) {
    _initInitialStates();
  }

  Future<void> _initInitialStates() async {
     try {
       print("GemmaModelService: Initializing model states from native side...");
       final List<dynamic>? downloadedModels = await _channel.invokeMethod('getDownloadedModels');
       final String? activeModelId = await _channel.invokeMethod('getActiveModel');
       
       // print("GemmaModelService: Downloaded models: $downloadedModels");
       // print("GemmaModelService: Active model: $activeModelId");
       
       if (downloadedModels != null) {
          for (var id in downloadedModels) {
             ref.read(gemmaModelStateProvider.notifier).updateState(id as String, GemmaModelState.downloaded);
             // print("GemmaModelService: Restored downloaded state for $id");
          }
       }
       if (activeModelId != null && activeModelId.isNotEmpty) {
          ref.read(gemmaModelStateProvider.notifier).setActive(activeModelId);
          // print("GemmaModelService: Restored active model: $activeModelId");
       }
     } catch (e) {
       print("GemmaModelService: Failed to initialize Gemma states: $e");
     }
  }

  Stream<DownloadProgress> getDownloadProgressStream(String modelId) {
    return _progressChannel.receiveBroadcastStream().where((event) {
       // print('GemmaModelService: Raw progress event: $event');
       return event['modelId'] == modelId;
    }).map((event) {
       final progress = DownloadProgress(
         downloadedMB: (event['downloadedMB'] as num).toDouble(),
         totalMB: (event['totalMB'] as num).toDouble(),
         speedMBps: (event['speedMBps'] as num).toDouble(),
         percent: (event['percent'] as num).toDouble(),
       );
       // print('GemmaModelService: Progress for $modelId: ${progress.downloadedMB.toStringAsFixed(1)}/${progress.totalMB.toStringAsFixed(1)} MB (${(progress.percent * 100).toStringAsFixed(0)}%)');
       return progress;
    }).handleError((error) {
       print('GemmaModelService: Progress stream ERROR for $modelId: $error');
       ref.read(gemmaModelStateProvider.notifier).updateState(modelId, GemmaModelState.notDownloaded);
    });
  }

  Future<void> downloadModel(String modelId) async {
    ref.read(gemmaModelStateProvider.notifier).updateState(modelId, GemmaModelState.downloading);
    final modelConfig = GemmaModels.availableModels.firstWhere((m) => m.id == modelId);
    try {
      // print('GemmaModelService: Starting download for $modelId from ${modelConfig.downloadUrl}');
      final result = await _channel.invokeMethod('downloadModel', {
        'modelId': modelId,
        'downloadUrl': modelConfig.downloadUrl,
      });
      // print('GemmaModelService: Download completed for $modelId, result=$result');
      ref.read(gemmaModelStateProvider.notifier).updateState(modelId, GemmaModelState.downloaded);
    } catch (e) {
      print('GemmaModelService: Download failed for $modelId: $e');
      ref.read(gemmaModelStateProvider.notifier).updateState(modelId, GemmaModelState.notDownloaded);
    }
  }

  Future<void> cancelDownload(String modelId) async {
    await _channel.invokeMethod('cancelDownload', {'modelId': modelId});
    ref.read(gemmaModelStateProvider.notifier).updateState(modelId, GemmaModelState.notDownloaded);
  }

  Future<void> activateModel(String modelId) async {
    try {
      print("GemmaModelService: Activating model $modelId...");
      await _channel.invokeMethod('activateModel', {'modelId': modelId});
      // Only update state if native call succeeded
      ref.read(gemmaModelStateProvider.notifier).setActive(modelId);
      print("GemmaModelService: Model $modelId activated successfully");
    } catch (e) {
      print("GemmaModelService: Failed to activate model $modelId: $e");
      rethrow;
    }
  }

  Future<String> infer(String prompt, {String? systemInstruction, Uint8List? audioBytes, Uint8List? imageBytes}) async {
    final activeConfig = ref.read(activeGemmaModelProvider);
    if (activeConfig == null) {
       throw Exception("No active Gemma model selected.");
    }
    
    final result = await _channel.invokeMethod('infer', {
      'prompt': prompt,
      'modelId': activeConfig.id,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (audioBytes != null) 'audioBytes': audioBytes,
      if (imageBytes != null) 'imageBytes': imageBytes,
    });
    
    return result as String;
  }

  /// Stream inference - returns tokens as they arrive via EventChannel.
  /// The returned Stream emits Map events with 'type' and 'data'/'message' keys.
  /// Types: 'status' (loading/thinking), 'token' (partial text), 'done' (final result), 'error'.
  /// The Future completes with the final full response string.
  ({Stream<Map<String, dynamic>> stream, Future<String> result}) inferStream(
    String prompt, {
    String? systemInstruction,
  }) {
    final activeConfig = ref.read(activeGemmaModelProvider);
    if (activeConfig == null) {
      throw Exception("No active Gemma model selected.");
    }

    final tokenStream = _streamChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });

    final resultFuture = _channel.invokeMethod('inferStream', {
      'prompt': prompt,
      'modelId': activeConfig.id,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
    }).then((result) => result as String);

    return (stream: tokenStream, result: resultFuture);
  }

  /// Temporarily free the model from memory without deactivating it.
  /// The model will auto-reload on the next infer call.
  Future<void> freeModel() async {
    await _channel.invokeMethod('freeModel');
  }
}

final gemmaModelServiceProvider = Provider<GemmaModelService>((ref) {
  return GemmaModelService(ref);
});

final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  final gemmaModelService = ref.watch(gemmaModelServiceProvider);
  return VoiceCommandService(gemmaModelService);
});
