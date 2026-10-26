# Firestore rules tests

Tests the team-invitation rules (`invitations`, `inviteEmails`, `emailIndex`
and a person joining a startup) against `firestore.rules` in the local
Firestore emulator. Nothing here touches the real project.

    cd tools/rules_tests
    npm install
    npm test

Needs Java (for the emulator) and the Firebase CLI. Every line should say
PASS and the run ends with `ALL PASSED`.
