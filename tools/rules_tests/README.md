# Firestore rules tests

Tests the team-invitation rules (`invitations`, `inviteEmails`, `emailIndex`
and a person joining a startup) against `firestore.rules` in the local
Firestore emulator. Nothing here touches the real project.

    cd tools/rules_tests
    npm install
    npm test

Needs Java (for the emulator) and the Firebase CLI. Every line should say
PASS and the run ends with `ALL PASSED`.

## App-vs-rules parity (`npm run parity`)

`flutter test test/audit/rules_parity_export_test.dart` records every write the
app can make (all pick-list values, the biggest text/amount/list the forms
allow, sign-up, profile edits, startups, rounds, team invitations, bookmarks,
account deletion) in `build/rules_parity.json`. Then, from this folder:

    npm run parity

replays all of them against the real `firestore.rules` in the emulator. Every
write must be allowed; a refusal means the app and the rules disagree (or a
request went over the 1000-expression limit). If port 8080 is still taken by an
old emulator, run it through `sh run_emu.sh demo-parity parity.test.mjs`, which
stops the old one first.
