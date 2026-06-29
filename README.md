# Jupyter Notebook Server

Multi-User JupyterHub-Server für Data Science und Machine Learning Übungen an der DHBW. Eine VM mit vorinstalliertem JupyterHub + JupyterLab, alle Studierenden bekommen einen eigenen Account.

## Konzept

Eine VM, ein gemeinsamer JupyterHub: Dozent (Admin) + N Studierende als Linux-Accounts mit eigenem Notebook-Verzeichnis. JupyterHub authentifiziert per PAM gegen die Linux-User. Ressourcenschonend gegenüber "ein Notebook pro Studi-VM".

**Deploy-Strategien:**

- **`one-instance`** — ein JupyterHub für den ganzen Kurs, alle Studierenden als User darauf
- **`one-per-group`** — ein eigener JupyterHub pro Projektgruppe, Mitglieder als User auf der jeweiligen VM

`one-per-user` ist bewusst nicht aktiviert.

## Parameter

### Allgemein

| Parameter | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `app_name` | string | ja | Identifier (3-20 Kleinbuchstaben/Zahlen/`-`) |
| `admin_username` | email (user-picker) | ja | Dozent, erhält JupyterHub-Admin-Rechte und sudo auf der VM |
| `students` | list(email) (user-picker, multi) | bei `one-instance` | Studierende des Kurses |
| `student_groups` | groups (group-builder) | bei `one-per-group` | Projektgruppen |

### Jupyter-Optionen

| Parameter | Typ | Default | Beschreibung |
|---|---|---|---|
| `flavor_name` | selection | `gp1.medium` | VM-Größe |
| `notebook_directory` | string | `exercises` | Ordnername im Home jedes Users für Notebooks |

## Outputs

| Output | Sichtbar | Sensitive | Beschreibung |
|---|---|---|---|
| `instance_id` | nein | nein | VM-ID (intern) |
| `app_name` | ja | nein | Projektname |
| `jupyterhub_url` | ja | nein | `https://<floating-ip>` |
| `jupyter_version` | ja | nein | JupyterHub-Version |
| `ssh_command` | ja | nein | SSH-Vorlage (Key benötigt) |
| `admin_credentials` | nein | ja | Admin-Login + API-Token + persönliche notebook_url |
| `student_credentials` | nein | ja | Map email → {username, email, password, notebook_url} |
| `ssh_private_key` | nein | ja | SSH Private Key (RSA 4096) |

## Setup-Ablauf (cloud-init)

1. Ubuntu 22.04 + Pakete (`python3-pip`, `nginx`, `certbot`, `git`, `build-essential`)
2. NodeJS 20 für JupyterHubs `configurable-http-proxy`
3. JupyterHub + JupyterLab + Notebook via `pip3`
4. Python-Pakete: `pandas`, `numpy`, `matplotlib`, `scikit-learn`, `seaborn` (fest in `python_packages` Default)
5. User-Accounts (Admin + Studierende) mit eigenem Notebook-Ordner
6. Self-Signed SSL-Zertifikat
7. Nginx als Reverse-Proxy (Port 80 → 443 Redirect, 443 → JupyterHub auf 8000)
8. JupyterHub als Systemd-Service
9. UFW: Ports 22, 80, 443

## Username-Konvention

E-Mails werden zu Linux/JupyterHub-Usernames konvertiert. Der lokale Teil bleibt, jedes Domain-Token wird auf max. 2 Zeichen gekürzt (hält den Username unter dem Linux-Limit von 32 Zeichen).

| Email | Username |
|---|---|
| `s2327001@student.dhbw-mannheim.de` | `s2327001_st_dh-ma_de` |
| `prof1@dhbw-mannheim.de` | `prof1_dh-ma_de` |

JupyterHub nutzt diesen Username für PAM-Login.

## Zugriff

### Studierende

1. Browser öffnen: `jupyterhub_url` (`https://<floating-ip>`)
2. **Self-Signed Cert akzeptieren** (Browser-Warnung wegklicken)
3. Login mit Username + Passwort aus `student_credentials[<eigene-email>]`
4. JupyterLab öffnet sich automatisch in `/home/<username>/<notebook_directory>`
5. Persönliche Notebook-URL: `student_credentials[<email>].notebook_url`

### Dozent (Admin)

1. **JupyterHub Admin-Panel:** Login wie ein Student, dann `/hub/admin` öffnen → User-Liste, Stoppen/Starten fremder Notebooks, Token-Verwaltung
2. **API-Token:** `admin_credentials.api_token` für Automatisierung gegen die JupyterHub-REST-API
3. **VM per SSH:**
   ```bash
   ssh -i ./key.pem ubuntu@<floating-ip>
   sudo systemctl status jupyterhub        # Service-Status
   sudo journalctl -u jupyterhub -f        # Live-Logs
   sudo systemctl restart jupyterhub       # Neustart
   ```

### Typische Admin-Aufgaben

```bash
# Notebook eines Studis stoppen (auf der VM)
sudo systemctl restart jupyterhub

# Passwort eines Studis zurücksetzen
sudo passwd <username>

# Zusätzliches Python-Paket nachinstallieren (global)
sudo pip3 install <package>

# Wer ist gerade eingeloggt
who
```

## Ports

| Port | Zweck |
|---|---|
| 22 | SSH (nur Admin via Key) |
| 80 | HTTP → 301 Redirect auf HTTPS |
| 443 | HTTPS (JupyterHub via Nginx) |

## Hinweise

- **Self-Signed Zertifikat:** Browser warnt beim ersten Aufruf. Für Produktiv-Setups Let's Encrypt via `certbot` einrichten (Paket ist bereits installiert).
- **Ressourcen werden geteilt:** Bei 10 Studierenden auf einem `gp1.medium` (2 CPU, 4 GB) wird's bei rechenintensiven Notebooks eng. Für DataFrames > 1 GB lieber `gp1.large` wählen.
- **Notebook-Speicher:** Notebooks liegen in `/home/<username>/<notebook_directory>`. Bei VM-Destroy gehen sie verloren — Studierende sollten regelmäßig `git push` machen oder Notebooks lokal sichern.
