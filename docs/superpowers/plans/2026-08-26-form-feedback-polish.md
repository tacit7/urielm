# Button and form feedback polish implementation plan

1. Add failing shared-component tests for loading buttons, help text, invalid fields, and feedback announcements.
2. Implement the shared button, input, feedback, and loading-state CSS behavior.
3. Adopt the primitives in sign-in, signup, settings, forum search, new-thread, and report forms.
4. Add targeted LiveView/component assertions and verify no double-submit or accessibility regressions.
5. Build assets, run the detector and test suites, commit only scoped files, and complete EITS task 9254.
