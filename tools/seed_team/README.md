# Sample team members (seed_team)

Gives every dataset startup a team whose members each have a full public
profile (`publicProfiles/{id}`), so tapping a person opens a real profile.

Touches only: new `publicProfiles` documents (ids `seed-...`, `isSample: true`)
and the `teamMembers` list of dataset startups. Nothing else.

    cd tools/seed_team
    npm install
    node seed_team.mjs <service-account.json>            # dry run, writes nothing
    node seed_team.mjs <service-account.json> --write    # applies it

A backup of the original teams is saved in `backups/` before any write.
To undo: `node cleanup.mjs <service-account.json> backups/<file>.json --write`.
