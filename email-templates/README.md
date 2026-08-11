# Branded email templates — Mosaic Inner Circle

Supabase only allows editing email subject/body when **custom SMTP** is
configured (Authentication → Emails → SMTP Settings). Until then the
default Supabase emails are sent, unbranded but functional.

## To enable branded emails later

1. Create a free sending account (Brevo allows a plain Gmail sender address;
   Resend/Mailgun need a verified domain).
2. Verify the sender address the house will send from.
3. Paste the SMTP host / port / user / password into Supabase's SMTP settings.
4. The template editor unlocks — paste `reset-password.html` and
   `confirm-signup.html` with the subjects below.

Subjects:
- Reset Password → `Your key to the Inner Circle`
- Confirm Signup → `Welcome to the Inner Circle`
