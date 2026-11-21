# Start.sa For You backend

A small FastAPI server that builds each user's For You list with scikit-learn and keeps profile
text vectors (all-MiniLM-L6-v2 through FastEmbed) up to date. The logic follows section 2 of the
design document "Start.sa Matching and For You"; the plan is
`docs/superpowers/plans/2026-11-21-for-you-backend.md`.

| Endpoint | What it does |
|---|---|
| `POST /for-you` | Returns the signed-in user's top 20 (`{"items": [{"id", "kind", "score"}], "generatedAt"}`) |
| `POST /profile-text` | Body `{"kind": "startup" or "investor", "id"}`: re-encodes that profile's text after an edit (owner only) |
| `GET /health` | `{"status": "ok"}` |

Every request except `/health` needs `Authorization: Bearer <Firebase ID token>`.

## Local setup

```bash
brew install python@3.12
cd backend
python3.12 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt -c constraints.txt
```

`requirements.txt` lists the six packages the server uses; `constraints.txt` pins every package
(including their dependencies) to the exact versions that were tested. After an intentional upgrade,
regenerate it from a clean environment: `pip install -r requirements.txt && pip freeze > constraints.txt`.

## Tests

```bash
.venv/bin/pytest                        # fast suite
.venv/bin/pytest -m "slow or not slow"  # everything, including the model download and the sentence-transformers parity test
```

The Dart side of the For You parity check runs from the repository root:

```bash
flutter test test/recommender/for_you_parity_test.dart
```

If the scoring changes on purpose, regenerate its fixture with `.venv/bin/python -m tests.make_parity_fixture`.

## Running the server locally

The server reads the Firebase service-account key from an environment variable (never commit the key):

```bash
export FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)"
.venv/bin/uvicorn app.main:app --reload
```

The service account only needs the **Cloud Datastore User** role. Open http://127.0.0.1:8000/docs to try the endpoints.

## Connecting the app

Start the server on the Mac (set `FIREBASE_SERVICE_ACCOUNT_JSON` first, as described in "Running the server locally"). `--host 0.0.0.0` lets a phone on the same Wi-Fi reach it:

```bash
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then run the app from the repository root with the server's address:

```bash
flutter run --dart-define=FOR_YOU_API_URL=http://10.0.2.2:8000
```

| Where the app runs | Address |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| Real phone on the same Wi-Fi | `http://<the Mac's network address>:8000` |
| After deploying | `https://<service>.onrender.com` |

Without `--dart-define=FOR_YOU_API_URL=...` the app uses its built-in Dart ranking and never calls the server.

If the server is asleep or unreachable, For You shows the list saved on the phone, then the Dart list.
The first request after a sleep can take about a minute on Render Free.

A local `http://` address works in debug builds (`flutter run` is a debug build by default). Release builds only allow `https://`, so they need the deployed `https://<service>.onrender.com` address.

Deploy `firestore.rules` (it has the `notInterested` rule) with `firebase deploy --only firestore:rules` from the repository root before any app build with the ✕ reaches users. Otherwise the Not interested writes are denied, the keys are put back, and hidden cards reappear.

### Check it works

- Open For You: the server log shows `POST /for-you 200`.
- Tap the ✕ on a card: it disappears, and Undo brings it back.
- Edit a startup's description: the server log shows `POST /profile-text 200`.
- Stop the server and reopen For You: the saved list still shows.

## One-time vector backfill

Encodes every public startup and every investor whose text vector is missing or out of date.
Vectors are stored compactly in 16 documents (`vectorChunks/c00` … `c15`), so loading all of them
costs 16 Firestore reads:

```bash
.venv/bin/python -m scripts.backfill_vectors
```

It prints `{"written": n, "unchanged": n, "deleted": n, "failed": n}` and is safe to run again.

## Memory check

Render's free plan has 512 MB. This loads the app, 1,100 fake profiles and the real model, and fails above 450 MB:

```bash
.venv/bin/python -m scripts.memory_check
```

## Deploying on Render

Create a **Web Service** from this repository with:

| Setting | Value |
|---|---|
| Runtime | Docker |
| Root directory | `backend` |
| Region | Frankfurt |
| Instance type | Free |
| Health check path | `/health` |
| Environment variable (secret) | `FIREBASE_SERVICE_ACCOUNT_JSON` = the key file's JSON text |

The free instance sleeps after 15 minutes without requests and can take up to a minute to wake;
the app shows the last saved list meanwhile.
