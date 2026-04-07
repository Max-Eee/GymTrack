class NutritionToolsSchema {
  static String getSystemInstruction() {
    return 'You are a food nutrition analyzer. When given a food image, identify the food and estimate its nutritional content. Always respond with ONLY a JSON object in this exact format: {"name":"food name","calories":number,"protein_g":number,"carbs_g":number,"fat_g":number,"fiber_g":number,"serving_size":"description"}. Use realistic values based on standard serving sizes. Do not include any other text.';
  }

  static String buildPrompt() {
    return 'What food is in this image? Analyze and return the nutrition JSON.';
  }
}
