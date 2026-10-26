# Invitation e-mail relay (Google Apps Script)

Sends the team-invitation e-mails from a Gmail account, with no password in
the app and without Firebase's paid plan.

## Deploy (about 5 minutes, once)

1. Sign in to the Gmail account that will send the e-mails
   (startsa.app@gmail.com) and open <https://script.google.com>.
2. **New project**. Name it "Start.sa invitations".
3. Delete the sample code and paste the whole of `Code.gs` from this folder.
4. Click **Deploy -> New deployment**. Next to "Select type" click the gear
   icon and choose **Web app**.
   * Description: `Start.sa invitations`
   * Execute as: **Me**
   * Who has access: **Anyone**
5. Click **Deploy**. Google asks you to **Authorize access**: choose the
   account, click **Advanced -> Go to Start.sa invitations (unsafe) -> Allow**.
   (The script only sends e-mail and reads the invitation.)
6. Copy the **Web app URL** (it ends with `/exec`).
7. Put it in `lib/app_constants/app_config.dart` as `inviteRelayUrl` (or send
   it to Claude to do it).

## Changing the script later
After editing the code: **Deploy -> Manage deployments -> pencil -> Version:
New version -> Deploy**. The URL stays the same.

## Design
The e-mail copies the Firebase "Verify your email" / "Reset your password" templates (green header with the logo, white body, green button, grey footer). To change the look, edit `sendInvitation_` in `Code.gs` and redeploy a new version.

## Limits
A normal Gmail account can send about 100 invitation e-mails a day through
Apps Script. The script also refuses to e-mail the same invitation twice in
one hour.

## How it is protected
The app sends only the invitation id and the user's Firebase sign-in token.
The script checks the token with Firebase, reads the invitation with that same
token (so the Firestore security rules apply), and refuses unless the caller
is the person who created the invitation and it is still pending. The
address, names and wording come from the invitation, never from the request.
