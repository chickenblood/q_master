# l10n-arb-editing Skill

**Purpose:**
Always add new localized strings to the ARB file (e.g., `lib/l10n/app_en.arb`) when introducing or updating user-facing text in the codebase. Ensure all new UI strings are properly localized and referenced via `L10n.of(context)!`.

**Best Practices:**
- For every new user-facing string, add a corresponding entry to the ARB file with a clear, unique key.
- Use descriptive keys (e.g., `editWorkoutButtonText`, `shareWorkoutButtonText`, `startBeatdownButtonText`).
- When editing the ARB file, be extremely careful with JSON syntax (commas, quotes, braces). If you are unsure or cannot safely edit the file, ask the user for help.
- After updating the ARB file, run `dart run build_runner build --delete-conflicting-outputs` to regenerate localization code.
- Reference all user-facing strings in code via `L10n.of(context)!.yourKey`.
- Never leave hardcoded user-facing strings in the UI.

**Workflow:**
1. Identify all new or changed user-facing strings.
2. Add them to the ARB file with unique keys and English values.
3. Reference the keys in code using the generated `L10n` class.
4. Validate ARB file syntax before saving.
5. Run build_runner to update generated localization code.
6. Verify in the UI and with analyzer.

**If you cannot safely edit the ARB file, ask the user for help.**
