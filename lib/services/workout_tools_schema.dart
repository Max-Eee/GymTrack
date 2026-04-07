/// Function calling schema for workout logging tools
/// These tools are passed to the Gemma LLM to enable structured command execution
class WorkoutToolsSchema {
  
  /// Get the complete tools schema as a compact string for the LLM
  static String getToolsSchema() {
    return '''Tools (respond with JSON {"tool":"name","parameters":{...}}):
- add_exercise(exercise_name, sets=3): Add exercise to workout
- add_sets(exercise_name, sets, weight?, reps?): Add sets with weight/reps
- update_set(exercise_name, weight?, reps?, completed?): Update latest incomplete set
- update_specific_set(exercise_name, set_number, weight?, reps?, completed?): Update specific set by number
- add_set_to(exercise_name, sets): Append sets to existing exercise
- remove_exercise(exercise_name): Remove exercise
- complete_exercise(exercise_name): Mark ALL sets complete
''';
  }
  
  /// Get contextual instructions for the LLM
  static String getSystemInstructions() {
    return '''Workout logging assistant. Return ONLY JSON: {"tool":"name","parameters":{...}}

Rules:
- Match exercise names flexibly ("bench"="bench press", "chest press"="Flat Chest Press")
- "1st set"/"set 1" → update_specific_set with set_number
- Just weight/reps without set number → update_set (updates next incomplete set)
- "completed"/"done"/"finished" → set completed:true
- "complete [exercise]" → complete_exercise (ALL sets)
- If user says just a weight like "10kg", use update_set for the exercise being discussed
- Use the Workout context to identify the next set: ○=incomplete, ✓=done
- Weight in kg by default

Examples:
- "flat chest press 1st set 10kg 15 reps completed" → {"tool":"update_specific_set","parameters":{"exercise_name":"Flat Chest Press","set_number":1,"weight":10,"reps":15,"completed":true}}
- "bench press 80kg 8 reps" → {"tool":"update_set","parameters":{"exercise_name":"bench press","weight":80,"reps":8}}
- "10kg 12 reps" → {"tool":"update_set","parameters":{"exercise_name":"[most recent exercise]","weight":10,"reps":12}}
- "add squats" → {"tool":"add_exercise","parameters":{"exercise_name":"squats"}}
- "remove curls" → {"tool":"remove_exercise","parameters":{"exercise_name":"curls"}}
''';
  }
  
  /// Build a context string with current workout exercises and their set data
  /// Format: "ExerciseName[Set1:10kgx12✓,Set2:10kgx10○,Set3:empty○]"
  static String buildWorkoutContext(List<String> exerciseNames) {
    if (exerciseNames.isEmpty) {
      return "\nWorkout: empty";
    }
    return "\nWorkout: ${exerciseNames.join(', ')}";
  }
}
