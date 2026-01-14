# Jupyter Notebook Server Template

Multi-User JupyterHub Server für Data Science und Machine Learning Übungen an der DHBW.

## Überblick

Dieses Template erstellt einen vollständig konfigurierten JupyterHub-Server mit:

- ✅ **Multi-User Support**: Separate Accounts für jeden Studierenden
- ✅ **JupyterLab Interface**: Moderne Notebook-Umgebung
- ✅ **Pre-installed Packages**: pandas, numpy, matplotlib, scikit-learn, etc.
- ✅ **HTTPS Support**: Nginx Reverse Proxy mit SSL (Self-Signed)
- ✅ **PAM Authentication**: Email-basierte Benutzeranmeldung
- ✅ **Automatische User-Erstellung**: Alle Studierenden werden beim Deployment angelegt
- ✅ **Resource Management**: Fair-Share CPU/RAM Verteilung
- ✅ **Secure Password Generation**: Zufällige, starke Passwörter für jeden User

## Architektur

```
┌─────────────────────────────────────────────┐
│          Internet (HTTPS/443)               │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│          Nginx Reverse Proxy                │
│       (SSL Self-Signed, Port 443/80)        │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         JupyterHub (Port 8000)              │
│   ┌─────────────────────────────────────┐   │
│   │  PAM Authenticator                  │   │
│   │  (Username: email with _ separator) │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  student1_test_de                   │   │
│   │  → /home/student1_test_de/exercises │   │
│   │  → JupyterLab on Port 127.0.0.1     │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  dozent_test_de (Admin)             │   │
│   │  → Full access to all notebooks     │   │
│   │  → API Token für Automatisierung    │   │
│   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Parameter

### Pflichtparameter

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `student_emails` | `array` | Liste der Studierenden-E-Mails (min. 1) |
| `admin_email` | `string` | Dozenten-Email für Admin-Zugang |
| `cpu_cores` | `number` | CPU Kerne (2-8, Standard: 2) |
| `ram_mb` | `number` | RAM in MB (2048-16384, Standard: 4096) |
| `disk_gb` | `number` | Festplatte in GB (10-100, Standard: 20) |

### Optional

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `enable_gpu` | `boolean` | `false` | GPU-Support für Deep Learning |
| `python_packages` | `array` | `["pandas", "numpy", ...]` | Zusätzliche Python-Pakete |
| `notebook_directory` | `string` | `"exercises"` | Name des Notebook-Ordners im Home-Dir |
| `enable_git_sync` | `boolean` | `false` | Git-Repo Synchronisation |
| `git_repo_url` | `string` | `""` | Git-Repository URL |

### Infrastruktur (in `terraform.tfvars`)

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `flavor_name` | `string` | `"m1.medium"` | OpenStack Flavor (Hardware-Größe) |
| `image_name` | `string` | `"Ubuntu 22.04"` | OS Image Name |
| `network_name` | `string` | `"NAT"` | Internes Netzwerk |
| `external_network_name` | `string` | `"DHBW"` | Externes Netzwerk für Floating IP |
| `floating_ip_pool` | `string` | `"DHBW"` | Pool für öffentliche IPs |

## Deployment-Beispiel

### Über CloudStore API

```json
{
  "template_id": 3,
  "user_id": 1,
  "parameters": {
    "student_emails": [
      "student1@dhbw.de",
      "student2@dhbw.de",
      "student3@dhbw.de"
    ],
    "admin_email": "professor@dhbw.de",
    "cpu_cores": 4,
    "ram_mb": 8192,
    "disk_gb": 50,
    "python_packages": [
      "pandas",
      "numpy",
      "matplotlib",
      "scikit-learn",
      "seaborn"
    ],
    "notebook_directory": "exercises",
    "enable_git_sync": false
  }
}
```

### Manuelles Deployment

```bash
cd terraform
terraform init

# terraform.tfvars anpassen
nano terraform.tfvars

# Deployment starten
terraform apply
```

## Outputs

### Public Outputs

| Output | Beschreibung | Beispiel |
|--------|--------------|----------|
| `jupyterhub_url` | Login-URL | `https://141.72.XXX.XXX` |
| `server_info` | VM-Details | `{"deployment_id": "...", "student_count": 3}` |
| `installed_packages` | Python-Pakete | `["pandas", "numpy", ...]` |
| `jupyter_version` | JupyterHub Version | `"4.0.2"` |
| `access_instructions` | Anleitung | Multi-line Text |

### Sensitive Outputs (via `/deployments/{id}/keys`)

| Output | Beschreibung |
|--------|--------------|
| `admin_credentials` | `{"username": "dozent_test_de", "password": "...", "api_token": "..."}` |
| `student_credentials` | Map: `email -> {"username": "student1_test_de", "password": "...", "notebook_url": "..."}` |
| `ssh_private_key` | SSH Private Key (RSA 4096-bit) |
| `floating_ip` | Öffentliche IP-Adresse |
| `internal_ip` | Interne IP-Adresse |

## Benutzernamen-Konvention

**Wichtig**: Email-Adressen werden automatisch in gültige Unix-Usernamen umgewandelt:

- `@` wird zu `_`
- `.` wird zu `_`
- Alles in Kleinbuchstaben

**Beispiele**:

| Email | Username |
|-------|----------|
| `student1@test.de` | `student1_test_de` |
| `Max.Mustermann@dhbw.de` | `max_mustermann_dhbw_de` |
| `professor@mail.dhbw-mannheim.de` | `professor_mail_dhbw-mannheim_de` |

## Zugriff

### Studierende

1. URL öffnen: `https://<floating-ip>` (aus `jupyterhub_url`)
2. **Username**: `student1_test_de` (siehe `student_credentials`)
3. **Password**: Aus `student_credentials[email].password`
4. JupyterLab öffnet sich automatisch in `/home/<username>/exercises`

### Administrator

1. Login mit Username aus `admin_credentials.username` (z.B. `dozent_test_de`)
2. **Rechte**:
   - Zugriff auf alle User-Notebooks
   - Admin-Panel: `https://<ip>/hub/admin`
   - API-Token für Automatisierung
3. **SSH-Zugang**:
   ```bash
   ssh -i private_key.pem ubuntu@<floating-ip>
   ```

## Resource Allocation

Ressourcen werden **fair zwischen allen Usern aufgeteilt**:

```python
# Beispiel: 8 CPU Cores, 16GB RAM, 10 Studierende
cpu_per_user = 8 / 10 = 0.8 cores
ram_per_user = 16384 / 10 = 1638 MB
```

**Wichtig**: Die Werte in `cpu_cores` und `ram_mb` gelten für die **gesamte VM**, nicht pro User!

## Technische Details

### Cloud-Init Prozess

1. **System-Setup**: Ubuntu 22.04, Updates, Pakete
2. **NodeJS Installation**: v20 für `configurable-http-proxy`
3. **Python-Pakete**: JupyterHub, JupyterLab, Custom Packages
4. **User-Erstellung**: Automatisch für alle Studierenden + Admin
5. **Ordner-Struktur**: `/home/<username>/exercises` (automatisch)
6. **SSL-Zertifikat**: Self-Signed (OpenSSL)
7. **Nginx-Konfiguration**: Reverse Proxy mit HTTPS-Redirect
8. **Systemd-Service**: JupyterHub als Auto-Start Service

### JupyterHub-Konfiguration (Highlights)

```python
# PAM Authenticator
c.JupyterHub.authenticator_class = 'jupyterhub.auth.PAMAuthenticator'

# Admin User
c.Authenticator.admin_users = {'dozent_test_de'}

# Notebook Directory (relativ zum Home-Dir)
c.Spawner.notebook_dir = '/home/{username}/exercises'

# Umgebungsvariablen (PATH-Fix)
c.Spawner.environment = {
    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "LANG": "C.UTF-8"
}

# Prevent "Running as root" Error
c.Spawner.cmd = ["jupyterhub-singleuser", "--allow-root"]
```

## Mock-Modus Testing

```bash
cd terraform
terraform init
terraform apply \
  -var="use_mock_provider=true" \
  -var='student_emails=["test1@example.com","test2@example.com"]' \
  -var="admin_email=admin@example.com" \
  -var="deployment_id=mock-test-123"
```

**Erstellt**:
- ✅ Echte Passwörter für alle User
- ✅ SSH-Keys
- ✅ Outputs wie in Production
- ❌ Keine echte VM

## Vergleich mit `multi-student-vm`

| Feature | `multi-student-vm` | `jupyter-notebook-server` |
|---------|-------------------|--------------------------|
| **VMs** | 1 VM pro Student | 1 gemeinsame VM |
| **Isolation** | Vollständig (eigene VM) | Prozess-Level (JupyterHub) |
| **Kosten** | N × VM-Kosten | 1 × VM-Kosten |
| **Use Case** | Individuelle Projekte | Standardisierte Übungen |
| **SSH-Zugang** | Ja (pro Student) | Nur Admin |
| **Package Management** | Individuell | Zentral für alle |

## Kostenabschätzung

**Standard-Konfiguration** (4 Cores, 8GB RAM, 20 Studierende):
- Hourly: ~0.20 EUR
- Monthly: ~140 EUR

**GPU-Konfiguration** (8 Cores, 32GB RAM, 1x NVIDIA T4):
- Hourly: ~0.80 EUR
- Monthly: ~550 EUR

## Troubleshooting

### JupyterHub startet nicht

```bash
ssh ubuntu@<floating-ip>
sudo systemctl status jupyterhub
sudo journalctl -u jupyterhub -f
```

### Student kann sich nicht einloggen

```bash
# Check if user exists
sudo cat /etc/passwd | grep student@dhbw.de

# Reset password manually
sudo passwd student@dhbw.de
```

### Git-Sync funktioniert nicht

```bash
sudo bash /usr/local/bin/git-sync.sh
sudo cat /var/log/syslog | grep git-sync
```

## Weiterentwicklung

Potenzielle Features:

- [ ] Let's Encrypt Integration (automatische SSL-Zertifikate)
- [ ] LDAP/OAuth Integration (DHBW-SSO)
- [ ] nbgrader Integration (automatische Übungskorrektur)
- [ ] Resource Monitoring Dashboard
- [ ] Backup/Restore Funktionalität
- [ ] Container-basierte Spawner (Docker/K8s)

## Lizenz

MIT License - DHBW CloudStore Project