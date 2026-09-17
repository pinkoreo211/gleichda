# Supabase einrichten (Dashboard)

Diese Schritte machst du einmal pro Supabase-Projekt im Browser unter
<https://supabase.com/dashboard>. Du brauchst dafür keinen geheimen Key und
musst ihn auch niemandem geben.

## 1. Region prüfen

**Project Settings → General**: Die Region sollte in der EU liegen (z. B.
*Central EU (Frankfurt)*). Die Region lässt sich später nicht ändern – liegt
das Projekt außerhalb der EU, lieber jetzt ein neues Projekt anlegen.

## 2. Datenbank-Struktur anlegen

1. Links **SQL Editor** öffnen → **New query**.
2. Den kompletten Inhalt von
   `supabase/migrations/20260917120000_profiles_and_roles.sql` hineinkopieren.
3. **Run** klicken. Erwartet: „Success. No rows returned“.

Nur **einmal** ausführen. Ein zweites Mal meldet Fehler wie „already exists“ –
das ist dann harmlos, es wurde nichts verändert.

Danach unter **Table Editor** prüfen: Es gibt die Tabellen `profiles` und
`user_roles`, beide mit dem Hinweis „RLS enabled“.

## 3. E-Mail-Vorlagen auf Code umstellen

Die App meldet mit einem **Code** an, nicht mit einem Link. Supabase schickt
standardmäßig aber einen Link. Deshalb:

**Authentication → Emails → Templates**, dann für **beide** Vorlagen
„**Confirm sign up**“ (neue Konten) und „**Magic Link**“ (bestehende Konten):

- **Subject:** `Dein Anmeldecode: {{ .Token }}`
- **Body** (Inhalt komplett ersetzen):

```html
<h2>Dein Anmeldecode</h2>
<p>Gib diesen Code in der App ein:</p>
<p style="font-size:32px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
<p>Der Code ist nur kurze Zeit gültig. Wenn du keine Anmeldung angefordert
hast, kannst du diese E-Mail ignorieren.</p>
```

Wichtig ist nur, dass `{{ .Token }}` vorkommt. Jeweils **Save** klicken.

## 4. Anmelde-Einstellungen prüfen

**Authentication → Sign In / Providers → Email**:

- **Enable Email provider**: an
- **Confirm email**: an (der Code bestätigt die Adresse)

**Authentication → Sign In / Providers → User Signups**:
„Allow new users to sign up“ muss an sein.

## Gut zu wissen

- **Test-E-Mails:** Ohne eigenen E-Mail-Dienst verschickt Supabase nur wenige
  E-Mails pro Stunde und nur an Adressen von Mitgliedern deiner Supabase-
  Organisation. Zum Testen also die E-Mail-Adresse deines Supabase-Kontos
  verwenden. Vor der Beta brauchen wir einen eigenen E-Mail-Dienst (SMTP).
- **Admin-Rolle:** Die App kann niemals Admin-Rechte vergeben. Das geht nur
  hier im Dashboard (SQL Editor) durch das Team.
- **Nie in die App:** `service_role`- oder `sb_secret_…`-Keys. In die App gehört
  nur die Project URL und der Publishable Key (`sb_publishable_…`).
