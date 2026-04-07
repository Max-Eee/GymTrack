
enum GemmaModelState {
  notDownloaded,
  downloading,
  downloaded,
  active,
}

class GemmaModelConfig {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final double sizeGB;
  final bool isMultiModal;
  final String fileName;

  const GemmaModelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeGB,
    this.isMultiModal = true,
    required this.fileName,
  });
}

class GemmaModels {
  // HuggingFace resolve URLs for direct download
  // Gemma 4 models from litert-community are Apache-2.0 (no auth needed)
  // Gemma 3n models from google require Gemma license acceptance
  
  static const List<GemmaModelConfig> availableModels = [
    GemmaModelConfig(
      id: "gemma-4-e2b-it",
      name: "Gemma 4 E2B",
      description: "Gemma 4 effective 2B parameter model. Supports text, image, and audio input with up to 32K context. Apache-2.0 license. 2.58 GB.",
      downloadUrl: "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm",
      sizeGB: 2.58,
      fileName: "gemma-4-E2B-it.litertlm",
    ),
    GemmaModelConfig(
      id: "gemma-4-e4b-it",
      name: "Gemma 4 E4B",
      description: "Gemma 4 effective 4B parameter model. Higher quality than E2B with text, image, and audio support. Apache-2.0 license. 3.65 GB.",
      downloadUrl: "https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm",
      sizeGB: 3.65,
      fileName: "gemma-4-E4B-it.litertlm",
    ),
  ];
}
