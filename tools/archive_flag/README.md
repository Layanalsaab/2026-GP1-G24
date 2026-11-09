# isArchived for startups, investors and funding rounds (archive_flag)

`isArchived` is true on everything imported from the dataset (Crunchbase) and
false on everything made in the app. It replaces the older `isDataset` field
(investors and rounds), which this script removes.

    cd tools/archive_flag
    npm install
    node migrate.mjs <service-account.json>            # dry run, writes nothing
    node migrate.mjs <service-account.json> --write    # really writes
    node undo.mjs <service-account.json> [--write]     # back to the backup

- Startups: archived when `founderId` is `crunchbase-dataset`.
- Investors and rounds: archived when `isDataset` was true.
- It checks investors against the accounts in Authentication and every round
  against its startup, and stops before writing if they disagree.
- The old values go to `output/backup.json` before anything is written.

New startups, investors and rounds made in the app are saved with
`isArchived: false`, and firestore.rules makes sure nobody can set it to true
from the app.

`output/` is not committed (it lists real investor and startup ids).
