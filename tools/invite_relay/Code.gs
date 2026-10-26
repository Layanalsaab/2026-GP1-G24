/**
 * Start.sa invitation e-mail relay (Google Apps Script web app).
 *
 * The app sends { idToken, invitationId }. This script:
 *   1. checks the Firebase ID token (who is calling),
 *   2. reads the invitation from Firestore WITH THAT TOKEN (so the security
 *      rules apply) and checks the caller is the person who created it,
 *   3. sends the e-mail from this Google account (MailApp), with the text and
 *      address taken from the invitation, never from the request,
 *   4. replies { ok: true } or { ok: false, error: "..." }.
 *
 * No password is stored anywhere: the script runs under the Google account
 * that deploys it. See README.md for the deployment steps.
 */

const PROJECT_ID = 'startsa-ea49e';
// The public Web API key of the Firebase project (lib/firebase_options.dart).
const WEB_API_KEY = 'AIzaSyBwlOChGLt1IWyioAmX7heK7-bx_lWsi0Q';
const SENDER_NAME = 'Start.sa';
// The logo of the Verify email / Reset password e-mails.
const LOGO_URL = 'https://i.ibb.co/PvQK0Z2q/Whats-App-Image-2026-08-31-at-9-09-53-PM.jpg';
const INVITE_LINK_BASE = 'https://startsa-ea49e.web.app/invite';
const RESEND_AFTER_MS = 60 * 60 * 1000; // one e-mail per invitation per hour

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const idToken = String(body.idToken || '');
    const invitationId = String(body.invitationId || '');
    if (!idToken || !invitationId) return reply_(false, 'bad request');

    const uid = verifyToken_(idToken);
    if (!uid) return reply_(false, 'not signed in');

    const inv = readInvitation_(invitationId, idToken);
    if (!inv) return reply_(false, 'invitation not found');
    if (inv.invitedBy !== uid) return reply_(false, 'not your invitation');
    if (inv.status !== 'pending') return reply_(false, 'invitation is not pending');
    if (inv.lastSentAt && Date.now() - inv.lastSentAt < RESEND_AFTER_MS) {
      return reply_(false, 'sent recently');
    }
    if (MailApp.getRemainingDailyQuota() < 1) return reply_(false, 'daily limit reached');

    sendInvitation_(invitationId, inv);
    return reply_(true, '');
  } catch (err) {
    return reply_(false, String(err));
  }
}

/** The uid of the Firebase user behind [idToken], or null. */
function verifyToken_(idToken) {
  const res = UrlFetchApp.fetch(
    'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=' + WEB_API_KEY,
    {
      method: 'post',
      contentType: 'application/json',
      payload: JSON.stringify({ idToken: idToken }),
      muteHttpExceptions: true,
    }
  );
  if (res.getResponseCode() !== 200) return null;
  const users = JSON.parse(res.getContentText()).users;
  return users && users.length ? users[0].localId : null;
}

/** The invitation document, read with the caller's own token. */
function readInvitation_(id, idToken) {
  const url =
    'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID +
    '/databases/(default)/documents/invitations/' + encodeURIComponent(id);
  const res = UrlFetchApp.fetch(url, {
    headers: { Authorization: 'Bearer ' + idToken },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) return null;
  const f = JSON.parse(res.getContentText()).fields || {};
  const str = function (k) { return f[k] && f[k].stringValue ? f[k].stringValue : ''; };
  return {
    startupName: str('startupName'),
    emailLower: str('emailLower'),
    role: str('role'),
    roleText: str('roleText'),
    invitedBy: str('invitedBy'),
    invitedByName: str('invitedByName'),
    status: str('status'),
    newUser: !!(f.newUser && f.newUser.booleanValue),
    lastSentAt: f.lastSentAt && f.lastSentAt.timestampValue
      ? new Date(f.lastSentAt.timestampValue).getTime()
      : 0,
  };
}

function esc_(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function sendInvitation_(id, inv) {
  const who = inv.invitedByName || 'A founder';
  const startup = inv.startupName || 'a startup';
  const role = inv.role === 'coFounder' ? 'Co-founder' : 'Team member';
  const link = INVITE_LINK_BASE + '?i=' + encodeURIComponent(id);
  const subject = who + ' invited you to join ' + startup + ' on Start.sa';

  const text =
    'Hi,\n\n' +
    who + ' added you to the ' + startup + ' team on Start.sa as a ' + role + '.\n\n' +
    'If you have the Start.sa app installed, open this link:\n' + link + '\n' +
    "If you don't have the app yet, install it first, then come back to this email and open the link again.\n\n" +
    (inv.newUser ? 'Create your Start.sa account using this email, ' : 'Sign in or create your account using this email, ') + inv.emailLower +
    ", and you'll be added to the team automatically.\n\n" +
    "If you weren't expecting this, you can ignore this email.";

  // The same design as the "Verify your email" and "Reset your password"
  // e-mails (Firebase Authentication templates): green header with the logo,
  // white body, green button, grey footer.
  const html =
    '<table width="100%" cellpadding="0" cellspacing="0" style="background:#eef1f0;padding:24px 0;font-family:Arial,Helvetica,sans-serif;"><tr><td align="center">' +
    '<table width="480" cellpadding="0" cellspacing="0" style="border-radius:14px;overflow:hidden;border:1px solid #e6e8e7;">' +
    // Green header with logo
    '<tr><td align="center" bgcolor="#17502e" style="background:#17502e;padding:30px 24px;">' +
    '<table cellpadding="0" cellspacing="0"><tr><td bgcolor="#ffffff" style="background:#ffffff;border-radius:12px;padding:10px;">' +
    '<img src="' + LOGO_URL + '" alt="Start.sa logo" width="60" style="display:block;border:0;" />' +
    '</td></tr></table>' +
    '<p style="margin:12px 0 0 0;color:#d4e7da;font-size:13px;">Saudi Arabia&#39;s Startup &amp; Investment Hub</p>' +
    '</td></tr>' +
    // Body
    '<tr><td bgcolor="#ffffff" style="background:#ffffff;padding:34px;color:#1a1a1a;line-height:1.6;text-align:center;">' +
    '<h2 style="margin:0 0 12px 0;color:#17502e;font-size:21px;">You&#39;re invited to join ' + esc_(startup) + '</h2>' +
    '<p style="margin:0 0 6px 0;font-size:15px;color:#374151;"><strong>' + esc_(who) + '</strong> added you to the <strong>' + esc_(startup) +
    '</strong> team on Start.sa as a <strong>' + esc_(role) + '</strong>.</p>' +
    '<p style="margin:0 0 28px 0;font-size:15px;color:#374151;">If you have the Start.sa app installed, tap the button below. ' +
    'If you don&#39;t have it yet, install the app first, then come back to this email and tap the button.</p>' +
    '<table cellpadding="0" cellspacing="0" align="center"><tr><td align="center" bgcolor="#1E7A3C" style="border-radius:9px;">' +
    '<a href="' + esc_(link) + '" style="display:inline-block;padding:13px 34px;color:#ffffff;text-decoration:none;font-weight:bold;font-size:15px;">' + (inv.newUser ? 'Create your account' : 'Open Start.sa') + '</a>' +
    '</td></tr></table>' +
    '<p style="margin:28px 0 0 0;font-size:15px;color:#374151;">' + (inv.newUser ? 'Create your Start.sa account using this email, ' : 'Sign in or create your account using this email, ') + '<strong>' + esc_(inv.emailLower) +
    '</strong>, and you&#39;ll be added to the team automatically.</p>' +
    '<p style="margin:32px 0 0 0;font-size:11.5px;color:#9aa1a8;">Button not working? Paste this link into your browser:<br>' +
    '<a href="' + esc_(link) + '" style="color:#9aa1a8;word-break:break-all;">' + esc_(link) + '</a></p>' +
    '</td></tr>' +
    // Footer
    '<tr><td bgcolor="#f7f8f8" style="background:#f7f8f8;padding:18px 34px;text-align:center;">' +
    '<p style="margin:0;font-size:12px;color:#9aa1a8;">If you weren&#39;t expecting this, you can safely ignore this email.</p>' +
    '</td></tr>' +
    '</table></td></tr></table>';

  MailApp.sendEmail({
    to: inv.emailLower,
    subject: subject,
    body: text,
    htmlBody: html,
    name: SENDER_NAME,
  });
}

function reply_(ok, error) {
  return ContentService.createTextOutput(
    JSON.stringify(ok ? { ok: true } : { ok: false, error: error })
  ).setMimeType(ContentService.MimeType.JSON);
}
