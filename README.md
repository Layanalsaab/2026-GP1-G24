# Start.sa

A mobile application connecting the Saudi startup ecosystem in one place: founders, investors, and startup seekers.

## Introduction

The Saudi startup ecosystem is fragmented. Information about support programmes, funding opportunities, and startups is spread across disconnected sources, and founders and investors largely find one another through personal networks. In our field study of 37 questionnaire respondents and 14 interview participants, every investor surveyed reported discovering startups through personal relationships and referrals, and every one agreed that searching for startups matching their criteria takes a long time.

Start.sa addresses this by bringing startup discovery, founder–investor matching, and AI-assisted startup guidance into a single application.

**Goal:** to reduce the dependence on personal networks in the Saudi startup ecosystem by providing a centralised platform where startups, investors, and contributors can find one another on the basis of stated criteria and reliable information.

## Features

- **Startup profiles** — founders present their startup's sector, stage, business model, and current needs, with control over what is publicly visible
- **Search and discovery** — browse and filter Saudi startups by sector, stage, and location
- **Explore** — a personalised For You section and a Trending view of the most active startups
- **Matchmaking** — a hybrid recommendation system matching founders and investors on stated criteria
- **Requests and chat** — fundraising and investment requests, each with a dedicated conversation
- **Expression of interest** — startup seekers submit their details and proposed contribution to a founder
- **Startup Mentor** — AI-assisted guidance on market research, competitor analysis, and business development
- **Fundraising Calculator** — valuation and equity estimation appropriate to the startup's stage

## Technologies Used

| Layer | Technology |
|---|---|
| Mobile application | Flutter (Dart), Android |
| Authentication and database | Firebase |
| Backend services | Python |
| Generative AI | Gemini API |
| Design | Figma |
| Project management | Jira|

## Repository Structure

```
.
├── app/                  # Flutter application
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── main.dart
│   ├── assets/
│   └── pubspec.yaml
├── backend/              # Python services
│   ├── api/
│   ├── recommender/
│   ├── mentor/
│   └── requirements.txt
├── docs/                 # Reports and documentation
├── AUTHORS
└── README.md
```

## Launch Instructions

### Prerequisites

- Flutter SDK (3.x or later)
- Android Studio with an Android emulator, or a physical Android device
- Python 3.10 or later
- A Firebase project with Authentication and Firestore enabled

### Running the application

```bash
git clone https://github.com/<organisation>/2026-GP-24.git
cd 2026-GP-24/app
flutter pub get
flutter run
```

Firebase configuration files (`google-services.json`) are not committed to the repository. Obtain them from the Firebase console and place `google-services.json` in `app/android/app/`.

### Running the backend

```bash
cd backend
python -m venv venv
source venv/bin/activate        # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python -m api.main
```

API keys are read from environment variables and are not committed. Create a `.env` file in `backend/` based on `.env.example`.

## Project Status

In development. Sprint 1 in progress.

## Team

See [AUTHORS](AUTHORS).

**Supervisor:** Dr. Ebtisam Alabdulqader
**Course:** IT496 — Graduation Project
**Institution:** King Saud University, College of Computer and Information Sciences, Department of Information Technology
