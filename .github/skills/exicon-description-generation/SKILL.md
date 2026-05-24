# exicon-description-generation Skill

Purpose
Document and standardize how exercise descriptions are generated from Codex Exicon data for workout constants.

Use this skill when
- Regenerating lib/workouts/workout_constants.dart from Exicon data.
- Updating tool/generate_workout_completion_map.py matching logic.
- Maintaining description behavior for unresolved names.

Current rules
- Descriptions are optional in ExerciseEntry.
- If a description cannot be resolved from Codex or retained existing data, emit description: null.
- Generation still succeeds when descriptions are missing.
- The script must emit a warning summary listing missing descriptions.

Primary files
- tool/export_exicon_csv.py
- tool/generate_workout_completion_map.py
- lib/workouts/workout_constants.dart
- .tmp/exicon_export.csv

Workflow
1. Refresh source data from Codex Exicon.
2. Run the generator script.
3. Confirm workout constants are regenerated.
4. Review warning output for unresolved descriptions.
5. Spot-check representative resolved and unresolved entries in the generated Dart map.
6. Run analyzer and fix script-level issues before finishing.

Commands
- python3 tool/export_exicon_csv.py
- python3 tool/generate_workout_completion_map.py
- flutter analyze --no-fatal-infos

Matching guidance
- Prefer deterministic normalization and conservative matching.
- Use explicit aliases only for clear, trusted exercise equivalences.
- Avoid broad fuzzy matching that can map generic names incorrectly.
- Keep unresolved items as null rather than forcing weak guesses.

Expected script output
- Always prints: Workout constants regenerated.
- If unresolved descriptions exist, prints: WARNING: Missing descriptions for N exercises and then the list.

Validation checklist
- No syntax or analyzer errors in tool/generate_workout_completion_map.py.
- Generated lib/workouts/workout_constants.dart compiles cleanly.
- Unresolved exercises use description: null.
- Warning output appears when unresolved descriptions exist.
