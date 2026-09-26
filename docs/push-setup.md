# Push-Benachrichtigungen einrichten

> **Zwei Ordner, zwei völlig verschiedene Orte im Dashboard.**
>
> | Ordner | Sprache | Wohin |
> |---|---|---|
> | `supabase/migrations/*.sql` | SQL | **SQL Editor** |
> | `supabase/functions/*/index.ts` | TypeScript | **Edge Functions** |
>
> Eine `.ts`-Datei in den SQL Editor zu kopieren endet mit
> `syntax error at or near "//"`. Kaputt geht dabei nichts – die Abfrage
> wird komplett abgelehnt, bevor irgendetwas läuft.

Diese Schritte machst nur du: Sie brauchen Konten und Schlüssel, die mir
nicht gehören. Ich brauche von dir am Ende **zwei Dateien** – beide sind
keine Geheimnisse und dürfen ins Projekt.

Der **dritte** Schlüssel (Abschnitt 4) ist ein echtes Geheimnis. Den gibst
du **niemandem**, auch mir nicht – er wird direkt in Supabase eingetragen.

## Wie es funktioniert

```
Kunde bucht
  → Datenbank schreibt einen Zettel in notification_outbox
  → Supabase weckt die Edge Function „send-push"
  → Firebase schickt die Nachricht ans Handy von Max
```

Die App fragt nie selbst „schick jemandem einen Push". Sie kann es gar
nicht: Die Outbox-Tabelle hat für die App **keinerlei Rechte**, weder
lesen noch schreiben. Nur die Funktionen, die die eigentliche Handlung
ausführen, schreiben dort hinein – und die wissen aus der Buchung, wer
der Empfänger ist.

---

## 1. Firebase-Projekt anlegen

1. <https://console.firebase.google.com> öffnen, mit deinem Google-Konto
   anmelden.
2. **Projekt hinzufügen**.
3. Name: `GleichDa`. **Weiter**.
4. Google Analytics: **ausschalten** (brauchen wir nicht, spart eine
   Einwilligung). **Projekt erstellen**.

## 2. Android-App hinzufügen

1. Im Projekt auf das **Android-Symbol** klicken.
2. **Android-Paketname** – exakt so, ohne Tippfehler:

   ```
   com.gleichda.app
   ```

3. App-Alias: `GleichDa Android`. SHA-1 lässt du **leer** (brauchen wir
   erst für Google-Login).
4. **App registrieren**.
5. **`google-services.json` herunterladen** und nach
   `android/app/google-services.json` legen.

   Diese Datei liegt im Projekt und darf das auch: Sie enthält kein
   Geheimnis. Genau derselbe Inhalt steckt in jeder ausgelieferten
   Android-App und lässt sich aus jeder APK herauslesen. Der Schlüssel
   darin ist an den Paketnamen gebunden und nützt niemandem, der nicht
   ohnehin die App hat.

   Das eine echte Geheimnis ist der Dienstkonto-Schlüssel aus Abschnitt 4.
   Der kommt nie ins Projekt.

6. Die nächsten beiden Firebase-Bildschirme („SDK hinzufügen") kannst du
   überspringen – das mache ich.

## 3. iOS-App hinzufügen

Kannst du auch später machen, zusammen mit dem Mac. Falls jetzt:

1. **iOS-Symbol**, Bundle-ID:

   ```
   com.gleichda.app
   ```

2. **`GoogleService-Info.plist`** herunterladen → auch an mich.
3. Für iOS brauchst du zusätzlich einen **APNs-Schlüssel** aus dem Apple
   Developer Portal (kostenpflichtiges Programm). Das kommt mit dem
   iOS-Release; Android läuft unabhängig davon.

## 4. Server-Schlüssel – das Geheimnis

Damit Supabase bei Firebase senden darf:

1. In der Firebase-Konsole oben links aufs **Zahnrad** →
   **Projekteinstellungen**.
2. Reiter **Dienstkonten**.
3. **Neuen privaten Schlüssel generieren** → **Schlüssel generieren**.
   Es lädt eine `.json`-Datei herunter.

**Diese Datei ist ein Passwort für dein Firebase-Projekt.** Nicht ins
Projekt legen, nicht in Git, nicht an mich schicken.

4. Datei mit einem Texteditor öffnen, **gesamten Inhalt** kopieren.
5. Supabase-Dashboard → **Project Settings** → **Edge Functions** →
   **Secrets** (oder **Edge Functions → Manage secrets**).
6. Neues Secret:

   | Feld | Wert |
   |---|---|
   | Name | `FIREBASE_SERVICE_ACCOUNT` |
   | Value | der komplette Inhalt der JSON-Datei |

7. **Save**. Danach die heruntergeladene Datei von deinem Rechner löschen.

## 5. Edge Function veröffentlichen

Die Funktion liegt schon im Projekt unter
`supabase/functions/send-push/index.ts`.

**Im Dashboard** (ohne Installation):

1. Supabase → **Edge Functions** → **Deploy a new function** →
   **Via Editor**.
2. Name: `send-push`
3. Den kompletten Inhalt von `supabase/functions/send-push/index.ts`
   hineinkopieren.
4. **Deploy**.

## 6. Die Funktion wecken lassen

Damit ein neuer Zettel sofort verschickt wird:

1. Supabase → **Database** → **Webhooks** → **Create a new hook**.
2. Ausfüllen:

   | Feld | Wert |
   |---|---|
   | Name | `send_push_on_new_notification` |
   | Table | `notification_outbox` |
   | Events | nur **Insert** |
   | Type | **Supabase Edge Functions** |
   | Edge Function | `send-push` |
   | Method | `POST` |

3. **Create webhook**.

Die Funktion liest die Warteschlange selbst aus und ignoriert, was der
Webhook mitschickt. Das ist Absicht: Sie handelt nach dem, was in der
Datenbank steht, nicht nach dem, was ihr jemand erzählt. Dadurch arbeitet
sie auch eine Warteschlange ab, die sich während einer Störung angesammelt
hat.

> **Achtung beim Produktivprojekt:** Dieser Webhook ist die **einzige**
> Einstellung des Projekts, die nicht als Datei im Repository liegt. Alles
> andere ist eine Migration und läuft automatisch mit. Der Webhook wird im
> Dashboard geklickt und muss beim Anlegen des Produktivprojekts **von Hand
> wiederholt** werden — sonst entstehen dort Benachrichtigungen, die nie
> jemand abholt.
>
> Grund: Der Webhook braucht den Publishable Key im Authorization-Header,
> und der steht bei uns in `env/*.json` und damit bewusst nicht in Git.

### Der Schalter „Verify JWT"

An der Edge Function bleibt **„Verify JWT with legacy secret" eingeschaltet**.
Supabase empfiehlt im Hinweistext „OFF" — das gilt für Funktionen, die
ihre Zugangsprüfung selbst im Code machen. Unsere macht das nicht.

Wäre er aus, könnte jeder mit der URL die Funktion beliebig oft aufrufen.
An den Daten könnte er nichts anrichten — versendet wird nur, was ohnehin
legitim in der Warteschlange steht — aber er könnte das Firebase- und
Supabase-Kontingent verbrennen.

## 7. Prüfen, ob es geht

Nach einer Buchung im SQL Editor:

```sql
select kind, status, attempts, last_error, created_at, sent_at
from public.notification_outbox
order by created_at desc
limit 5;
```

| Was dort steht | Bedeutung |
|---|---|
| `status = 'sent'` | Zugestellt |
| `status = 'pending'`, `attempts = 0` | Die Funktion wurde nie geweckt → Webhook prüfen (Abschnitt 6) |
| `status = 'pending'`, `attempts > 0` | Versucht und fehlgeschlagen → `last_error` lesen |
| `status = 'failed'` | Dreimal gescheitert, wird nicht mehr versucht |

Registrierte Geräte:

```sql
select platform, created_at from public.user_push_tokens;
```

Ist die Tabelle leer, hat noch niemand die Berechtigung erteilt – oder
Firebase ist in der App noch nicht eingebaut.

## Was schiefgehen darf

**Eine Buchung schlägt nie fehl, weil ein Push nicht ankommt.** Das
Schreiben des Zettels steckt in einem eigenen Block: Geht dabei etwas
schief, bleibt die Buchung bestehen und niemand wird benachrichtigt. Das
ist die richtige Reihenfolge – ein Auftrag, der nicht ankommt, ist ein
größeres Problem als eine Nachricht, die nicht ankommt.

Ein Gerät, das Firebase ablehnt (App deinstalliert), wird aus
`user_push_tokens` gelöscht. Sonst würde es bei jedem Versand erneut
probiert.

## Was bewusst *nicht* im Push steht

Kein Straßenname, keine Telefonnummer, nicht der Text, den der Kunde
geschrieben hat, und bei Chat-Nachrichten nicht die Nachricht selbst. Ein
Push erscheint auf dem gesperrten Bildschirm – dem unprivatesten Ort, an
dem ein Satz landen kann. Dort steht nur, *dass* etwas passiert ist.
