import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/gemma_models.dart';
import '../../../services/gemma_model_service.dart';

class ModelSettingsScreen extends ConsumerStatefulWidget {
  const ModelSettingsScreen({super.key});

  @override
  ConsumerState<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends ConsumerState<ModelSettingsScreen> {
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    final modelStates = ref.watch(gemmaModelStateProvider);
    final service = ref.read(gemmaModelServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: GemmaModels.availableModels.length,
              itemBuilder: (context, index) {
                final model = GemmaModels.availableModels[index];
                final state = modelStates[model.id] ?? GemmaModelState.notDownloaded;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                model.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _buildStatusIcon(state),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          model.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Size: ${model.sizeGB} GB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _buildActionArea(context, model, state, service),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(GemmaModelState state) {
    switch (state) {
      case GemmaModelState.active:
        return const Icon(Icons.check_circle, color: Colors.green);
      case GemmaModelState.downloaded:
        return const Icon(Icons.check, color: Colors.blue);
      case GemmaModelState.downloading:
        return const SizedBox.shrink();
      case GemmaModelState.notDownloaded:
        return const Icon(Icons.cloud_download_outlined, color: Colors.grey);
    }
  }

  Widget _buildActionArea(BuildContext context, GemmaModelConfig model, GemmaModelState state, GemmaModelService service) {
    switch (state) {
      case GemmaModelState.notDownloaded:
        return ElevatedButton(
          onPressed: () async {
            setState(() => _errorMessage = null);
            // print('ModelSettingsScreen: Download button pressed for ${model.id}');
            // print('ModelSettingsScreen: URL = ${model.downloadUrl}');
            try {
              await service.downloadModel(model.id);
              // print('ModelSettingsScreen: Download completed for ${model.id}');
            } catch (e) {
              print('ModelSettingsScreen: Download error for ${model.id}: $e');
              if (mounted) {
                setState(() => _errorMessage = 'Download failed: $e');
              }
            }
          },
          child: Text('Download (${model.sizeGB} GB)'),
        );
      case GemmaModelState.downloading:
        return StreamBuilder<DownloadProgress>(
          stream: service.getDownloadProgressStream(model.id),
          builder: (context, snapshot) {
            print('ModelSettingsScreen: StreamBuilder state=${snapshot.connectionState} hasData=${snapshot.hasData} hasError=${snapshot.hasError}');
            String progressText = "Connecting...";
            double? progressValue;
            if (snapshot.hasError) {
              progressText = "Error: ${snapshot.error}";
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              progressValue = data.percent;
              progressText = "${data.downloadedMB.toStringAsFixed(1)} MB of ${data.totalMB.toStringAsFixed(1)} MB (${data.speedMBps.toStringAsFixed(1)} MB/s)  ${(data.percent * 100).toStringAsFixed(0)}%";
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progressValue),
                const SizedBox(height: 4),
                Text(progressText, style: Theme.of(context).textTheme.bodySmall),
                TextButton(
                  onPressed: () => service.cancelDownload(model.id),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      case GemmaModelState.downloaded:
        return ElevatedButton(
          onPressed: () async {
            setState(() => _errorMessage = null);
            try {
              await service.activateModel(model.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${model.name} is now active. It will load automatically when you first use it.'),
                    backgroundColor: AppColors.surfaceVariantDark,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() => _errorMessage = 'Failed to activate model: $e');
              }
            }
          },
          child: const Text('Set Active'),
        );
      case GemmaModelState.active:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: null,
              child: const Text('Active Model'),
            ),
            const SizedBox(height: 4),
            Text(
              'Loads automatically when needed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }
}