# Agents

For all Git, branching, and release operations, strictly follow the rules in [./GIT_WORKFLOW.md](./GIT_WORKFLOW.md).

Always showcase and align on the complete scope, architecture, and edge cases of any feature or fix before writing any code, especially for big features.

When preparing a Pull Request reminder, always format the PR Description inside a fenced markdown code block (```markdown ... ```) so it can be easily copied with one click into GitHub.

## Terminal & Background Commands (Windows)
- On Windows, Flutter/Dart CLI tools (`flutter analyze`, `flutter test`, `flutter gen-l10n`, etc.) hang silently with empty background logs when run inside the restricted terminal sandbox (`BypassSandbox: false`).
- Always run those background/CLI verification commands as **standalone single commands** (do not chain multiple commands with `;` or `&&`) using **`BypassSandbox: true`** so output streams live and the command completes cleanly.
- If you run `flutter analyze` and `flutter test`, invoke them as two separate `run_command` calls (`BypassSandbox: true`), not combined in one shell string.
