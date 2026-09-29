# Supabase einrichten (Dashboard)

Diese Schritte machst du einmal pro Supabase-Projekt im Browser unter
<https://supabase.com/dashboard>. Du brauchst dafür keinen geheimen Key und
musst ihn auch niemandem geben.

## 1. Region prüfen

**Project Settings → General**: Die Region sollte in der EU liegen (z. B.
*Central EU (Frankfurt)*). Die Region lässt sich später nicht ändern – liegt
das Projekt außerhalb der EU, lieber jetzt ein neues Projekt anlegen.

## 2. Datenbank-Struktur anlegen

Die Struktur der Datenbank liegt als Dateien im Ordner
`supabase/migrations/`. Jede Datei wird **genau einmal** ausgeführt, und zwar
**in der Reihenfolge ihrer Namen** (die Zahl vorne ist das Datum).

Für jede Datei:

1. Links **SQL Editor** öffnen → **New query**.
2. Den kompletten Inhalt der Datei hineinkopieren.
3. **Run** klicken. Erwartet: „Success. No rows returned“.

Bisher gibt es diese Dateien:

| Datei | Legt an | Ausgeführt |
|---|---|---|
| `20260917120000_profiles_and_roles.sql` | `profiles`, `user_roles` | ✅ |
| `20260920120000_service_requests.sql` | `service_requests` | ✅ |
| `20260920140000_service_catalog.sql` | Servicekatalog (Kategorien, Leistungen, Preise) | ✅ |
| `20260921120000_providers.sql` | Dienstleister-Profile, ihre Leistungen und Dokumente | ✅ |
| `20260921140000_provider_prices.sql` | Eigene Preise der Anbieter je Leistung | ✅ |
| `20260922120000_matching.sql` | Anfrage mit Leistung verknüpfen; Suchfunktion für passende Anbieter | ✅ |
| `20260922140000_request_contacts.sql` | Ort bei der Anfrage; Anfrage an einen Anbieter senden; der Anbieter sieht sie | ✅ |
| `20260922160000_request_responses.sql` | Anbieter nimmt eine Anfrage an oder lehnt sie ab; Kunde sieht den Status | ✅ |
| `20260923120000_chat.sql` | Privater Chat pro angenommenem Auftrag (`conversations`, `messages`) | ✅ |
| `20260923140000_conversation_list.sql` | Leseabfrage für den Chats-Tab (nur eine Funktion, keine neue Tabelle) | ✅ |
| `20260925120000_no_self_hire.sql` | Niemand beauftragt sich selbst (ersetzt drei Funktionen, keine Tabellenänderung) | ✅ |
| `20260925140000_job_status_values.sql` | **Teil 1:** Statuswerte und Zeitstempel für den Auftragsablauf | ✅ |
| `20260925160000_job_status.sql` | **Teil 2:** Aufträge lesen und einen Schritt weiterschalten | ✅ |
| `20260925180000_reviews.sql` | Bewertungen nach abgeschlossenen Aufträgen; Durchschnitt in der Anbietersuche | ✅ |
| `20260926120000_provider_verification.sql` | Nachweise hochladen: Spalten, privater Storage-Bucket, Prüf-Funktionen fürs Team | ✅ |
| `20260926140000_document_upload_limits.sql` | Größe und Dateiformat schon im Bucket begrenzen, nicht nur in der App | ✅ |
| `20260926160000_booking.sql` | Festpreis-Buchung: Adresse, gewählte Preisoption, Wunschtermin; Servicevorschlag und buchbare Anbieter | ✅ |
| `20260927120000_push_notifications.sql` | Geräte-Tokens und Benachrichtigungs-Warteschlange (siehe docs/push-setup.md) | ✅ |
| `20260929120000_profile_names_and_avatars.sql` | Profilbild je Konto (öffentlicher Bucket `avatars`); Name und Foto in allen Listen | ⬜ |

Die beiden Auftragsstatus-Dateien sind **getrennt und in dieser Reihenfolge**
auszuführen. Postgres erlaubt es nicht, einen gerade erst angelegten
Statuswert im selben Durchlauf schon zu verwenden — zusammen in einem
Fenster ausgeführt schlägt es an einer Kleinigkeit fehl, die mit der
Änderung nichts zu tun hat.

Ein zweites Ausführen derselben Datei meldet Fehler wie „already exists“ –
das ist harmlos, es wurde dann nichts verändert.

Danach unter **Table Editor** prüfen: Jede Tabelle trägt den Hinweis
„RLS enabled“. Fehlt der, stimmt etwas nicht – dann bitte melden, denn ohne
RLS könnte jeder die Daten aller anderen lesen.

**Wichtig bei neuen Dateien:** Eine bereits ausgeführte Migrationsdatei wird
nie mehr geändert. Änderungen an der Datenbank kommen immer als neue Datei.
So bleibt diese Liste eine verlässliche Geschichte der Datenbank – was
spätestens beim Anlegen des Produktivprojekts vor dem Start wichtig wird.

### 2a. Nachweise: Bucket prüfen

Die Verifizierungs-Migration legt auch einen **Speicherort für Dateien** an.
Nach dem Ausführen unter **Storage** nachsehen:

- Es gibt einen Bucket `provider-documents`.
- Er ist **nicht** öffentlich (kein „Public“-Hinweis daneben).

Ist der Bucket öffentlich, bitte sofort melden – dann könnte jeder mit dem
richtigen Link fremde Ausweise ansehen.

Falls beim Ausführen eine Fehlermeldung zu `storage.buckets` oder
`storage.objects` kommt (manche Supabase-Projekte erlauben das nur über die
Oberfläche): den Bucket unter **Storage → New bucket** anlegen, Name
`provider-documents`, **Public bucket ausgeschaltet lassen**, und unter
**Policies** die drei Regeln von Hand eintragen. Die Bedingungen stehen
wörtlich in der Migrationsdatei – einfach melden, dann gehe ich sie mit dir
durch.

### 2b. Nachweise prüfen (Team)

Das läuft heute im Dashboard, es gibt noch keinen Adminbereich in der App.
Im **SQL Editor**:

```sql
-- Was liegt zur Prüfung da?
select * from public.pending_verifications();
```

Die Datei selbst liegt unter **Storage → provider-documents** im Ordner mit
der `provider_id`. Danach pro Dokument entscheiden:

```sql
-- Angenommen
select public.review_provider_document('<document_id>', 'accepted');

-- Abgelehnt, mit Grund (den sieht der Dienstleister in der App)
select public.review_provider_document(
  '<document_id>', 'rejected', 'Das Foto ist unscharf.'
);
```

Erst wenn **alle** nötigen Nachweise passen, wird das Profil verifiziert:

```sql
select public.set_provider_verification('<provider_id>', 'verified');
```

Das ist bewusst ein eigener, bewusster Schritt. Die App kann diese drei
Funktionen nicht aufrufen – weder ein Dienstleister noch ein Kunde, und
auch keine KI. Nur eine Person hier im Dashboard.

Soll eine Leistung mehr verlangen als Ausweis und Gewerbeanmeldung:

```sql
insert into public.service_document_requirements (service_id, document_type)
select id, 'qualification' from public.services where slug = 'lampenmontage';
```

## 3. Eigenen E-Mail-Versand einrichten (kostenlos)

Seit Juni 2026 lässt Supabase die E-Mail-Vorlagen bei neuen Gratis-Projekten
nur noch ändern, wenn ein **eigener E-Mail-Versand (SMTP)** eingerichtet ist.
Ohne das verschickt Supabase einen **Link** – unsere App braucht aber einen
**Code**. Deshalb ist dieser Schritt Pflicht.

Nebenbei löst es ein zweites Problem: Der eingebaute Versand von Supabase
schickt nur an Mitglieder der eigenen Organisation. Mit eigenem Versand können
später auch echte Testnutzer aus Wien Mails bekommen.

Es gibt zwei kostenlose Wege. **Variante A ist für den Anfang einfacher.**

---

## Variante A: eigenes Gmail verwenden (am einfachsten)

Die eigene Gmail-Adresse bringt bereits einen Mailserver mit. Supabase braucht
nur die Erlaubnis, darüber zu verschicken.

1. **Bestätigung in zwei Schritten** im Google-Konto einschalten
   (Google-Konto → Sicherheit). Ohne das gibt es keine App-Passwörter.
2. <https://myaccount.google.com/apppasswords> öffnen, App-Passwort anlegen,
   Name z. B. `Supabase`. Google zeigt ein **16-stelliges Passwort** – kopieren.
3. In Supabase unter **Authentication → Emails → Set up SMTP** eintragen:

| Feld | Wert |
|---|---|
| Sender email | die eigene Gmail-Adresse |
| Sender name | `GleichDa` |
| Host | `smtp.gmail.com` |
| Port | `587` |
| Username | die eigene Gmail-Adresse |
| Password | das 16-stellige **App-Passwort** (nicht das Gmail-Passwort) |

Grenzen: 500 E-Mails pro Tag, und als Absender steht eine private
Gmail-Adresse. Für Entwicklung und eine kleine Beta reicht das. Vor dem
öffentlichen Start wechseln wir auf eine eigene Domain (Variante B).

---

## Variante B: Brevo (später, mit eigener Domain)

300 E-Mails pro Tag, keine Kreditkarte, keine eigene Domain nötig. Sinnvoll,
sobald die Mails nicht mehr von einer privaten Adresse kommen sollen.

### 3a. Brevo-Konto anlegen

1. <https://www.brevo.com> → **Sign up free**. Mit der eigenen E-Mail-Adresse
   registrieren und die Bestätigungsmail anklicken.
2. Neue Konten werden von Brevo **einmalig manuell freigeschaltet**. Wenn der
   Versand am Anfang blockiert ist: kurz warten, das ist normal.

### 3b. Absenderadresse bestätigen

1. Links **Senders, Domains & Dedicated IPs** → Reiter **Senders**.
2. **Add a sender**: Name (z. B. `GleichDa`) und die Absender-E-Mail eintragen.
3. Brevo schickt einen **6-stelligen Code** an diese Adresse. Code eingeben →
   der Absender ist bestätigt.

Ohne eigene Domain funktioniert eine normale Adresse (z. B. Gmail). Vor dem
öffentlichen Start ersetzen wir das durch eine eigene Domain, damit die Mails
seriöser aussehen und zuverlässiger ankommen.

### 3c. SMTP-Schlüssel erzeugen

1. Oben rechts auf den Kontonamen → **SMTP & API**.
2. Reiter **SMTP** → **Generate a new SMTP key**, Name z. B. `supabase`.
3. Den Schlüssel **sofort kopieren** – er wird nur einmal angezeigt.

Auf derselben Seite stehen auch **SMTP server** und **Login**. Beides wird
gleich gebraucht.

Wichtig: Es muss der **SMTP-Key** sein, nicht der API-Key und nicht das
Konto-Passwort.

### 3d. In Supabase eintragen

**Authentication → Emails → Reiter SMTP Settings** (oder der Knopf
**Set up SMTP** im blauen Hinweis), dann **Enable Custom SMTP** anschalten:

| Feld | Wert |
|---|---|
| Sender email | die in 3b bestätigte Adresse |
| Sender name | `GleichDa` |
| Host | `smtp-relay.brevo.com` |
| Port | `587` |
| Username | der **SMTP login** aus 3c (nicht der Host!) |
| Password | der **SMTP key** aus 3c |

**Save** klicken. Danach ist der blaue Hinweis weg und die Vorlagen in
Schritt 4 sind bearbeitbar.

## 4. E-Mail-Vorlagen auf Code umstellen

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

Tipp: Wenn die Vorschau („Preview“) grau bleibt und „Verbindung verweigert“
zeigt, ist das ein Anzeigefehler im Dashboard. Über den Knopf **Source**
daneben lässt sich der Inhalt trotzdem sehen und bearbeiten.

## 5. Anmelde-Einstellungen prüfen

**Authentication → Sign In / Providers → Email**:

- **Enable Email provider**: an
- **Confirm email**: an (der Code bestätigt die Adresse)

**Authentication → Sign In / Providers → User Signups**:
„Allow new users to sign up“ muss an sein.

## Gut zu wissen

- **Test-E-Mails:** Solange kein eigener Versand (Schritt 3) eingerichtet ist,
  verschickt Supabase nur wenige E-Mails pro Stunde und nur an Adressen von
  Mitgliedern deiner Supabase-Organisation. Mit Brevo fällt beides weg.
- **Admin-Rolle:** Die App kann niemals Admin-Rechte vergeben. Das geht nur
  hier im Dashboard (SQL Editor) durch das Team.
- **Nie in die App:** `service_role`- oder `sb_secret_…`-Keys. In die App gehört
  nur die Project URL und der Publishable Key (`sb_publishable_…`).
