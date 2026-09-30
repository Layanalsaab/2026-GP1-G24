# Start.sa

A mobile application connecting the Saudi startup ecosystem in one place: founders, investors, and startup seekers.

## Introduction

The Saudi startup ecosystem is fragmented. Information about support programmes, funding opportunities, and startups is spread across disconnected sources, and founders and investors largely find one another through personal networks.

Our field study of 37 questionnaire respondents and 14 interview participants found that every investor surveyed discovers startups through personal relationships and referrals, and every one agreed that searching for startups matching their criteria takes a long time. On the founder side, 56% reach investors through personal connections and 31% have never attempted to contact one.

**Goal:** to reduce the dependence on personal networks in the Saudi startup ecosystem by providing a central platform where startups, investors, and contributors can find one another on the basis of stated criteria and reliable information.

## Features

| Feature | For | Description |
|---|---|---|
| Startup Management | Founders | Create and manage multiple startups, control public or private visibility, and state what each startup needs |
| Startup Activity Dashboard | Founders | Views, bookmarks, and detail expansions for each startup |
| Ask Gemini | Founders | AI-assisted answers to questions about the startup |
| Fundraising Calculator | Founders, investors | Valuation and equity estimates, used by founders to plan a round and by investors to judge whether a deal is fair |
| Support Directory | Founders | Accelerators, incubators, and support organisations in one place |
| Investment Association | Founders, investors | A founder records an investor who backed the startup; the investor approves or rejects, and chooses once whether the link is public |
| Investor–Startup Matchmaking | Founders, investors | Reciprocal matching on sector, stage, funding requirement, business model, and location, with a match score and an explanation |
| Startup Hub | Founders, investors, startup seekers | A searchable directory of public Saudi startups |
| Explore Page | Founders, investors | Personalised recommendations, alongside trending startups and investors |
| Request Management | Founders, investors | Fundraising and investment requests, each with a dedicated chat |
| Bookmark Management | Founders, investors | Save startups and investors for later |
| Notification Management | Founders, investors | Alerts for requests, fundraising, and investment opportunities |
| Expression of Interest | Startup seekers | Submit details and a proposed contribution to a founder |

Startup seekers use Start.sa without an account: they can browse the Startup Hub, view trending startups, and submit an Expression of Interest.

## Technologies

| Layer | Technology | Purpose |
|---|---|---|
| Mobile application | Flutter (Dart), Android | Single codebase for the Android application |
| Authentication, database, storage | Firebase | User accounts, Firestore data, and file storage |
| Generative AI | Gemini Flash via Firebase AI Logic | Powers Ask Gemini, and keeps the API key off the device |
| Recommender system | Python, scikit-learn, LightFM | Content-based ranking and the collaborative component |
| Email | Gmail SMTP | Invitations to investors who do not yet have an account |
| Design | Figma | Interface design and prototyping |
| Project management | Jira, Confluence | Sprint planning, backlog, and documentation |

## Launch Instructions

### Prerequisites

- Flutter SDK 3.x or later
- Android Studio with an emulator, or a physical Android device
- Python 3.10 or later
- A Firebase project with Authentication, Firestore, and AI Logic enabled

## Project Status

In development. Sprint 1 in progress.

## Team


## Prepared by

| Name | ID |
|---|---|
| Layan Alsaab | 445201356 |
| Shahad Alabdulakrim | 445202212 |
| Noura Alawwad | 445201445 |
| Sara Alswailem | 445204223 |

## Supervised by

Dr. Ebtisam Alabdulqader


