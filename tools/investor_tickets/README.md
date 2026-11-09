# Investor ticket size and tickets (investor_tickets)

Scripts for the dataset investors (`isArchived: true`; called `isDataset`
before 9 Nov) and the new `tickets`
collection. App investors are never touched.

    cd tools/investor_tickets
    npm install
    node export_investors.mjs <service-account.json>        # read only
    node generate.mjs <crunchbase-investors.csv>            # no Firebase
    node upload.mjs <service-account.json>                  # dry run
    node upload.mjs <service-account.json> --write
    node undo.mjs <service-account.json> [--write]          # back to the backup

- `export_investors.mjs` saves the live investors to `output/investors_backup.json`
  (the backup) and `output/investors.csv`, the startups to `output/startups.json`,
  and lists any value that isn't one of the app's options.
- `generate.mjs` takes `investmentsCount` from the real "Number of Investments"
  in the Crunchbase file (matched by CB Rank), then builds `output/plan.json`
  plus `output/investors_new.csv` (every step per investor) and
  `output/tickets.csv` (with the raising startups each ticket fits). Seeds 2026
  and 2027.
- `upload.mjs` updates only `investmentsCount` and `ticketSize` of the dataset
  investors and writes the tickets (`<investorId>-T1`, `isSample: true`). It
  checks every value first and stops on any problem.
- `undo.mjs` puts the two fields back from the backup and deletes the sample
  tickets.

`output/` is not committed.
