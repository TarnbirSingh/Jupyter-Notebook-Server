# Jupyter Notebook Server Template

Multi-User JupyterHub Server für Data Science und Machine Learning Übungen an der DHBW.

## Überblick

Dieses Template erstellt einen vollständig konfigurierten JupyterHub-Server mit:

- ✅ **Multi-User Support**: Separate Accounts für jeden Studierenden
- ✅ **JupyterLab Interface**: Moderne Notebook-Umgebung
- ✅ **Pre-installed Packages**: pandas, numpy, matplotlib, scikit-learn, etc.
- ✅ **HTTPS Support**: Nginx Reverse Proxy mit SSL
- ✅ **Git Integration**: Automatische Synchronisation von Übungsmaterial
- ✅ **Optional GPU Support**: Für Deep Learning Workloads
- ✅ **Resource Management**: CPU/RAM Limits pro User
- ✅ **Idle Culling**: Automatisches Beenden inaktiver Notebooks

## Architektur

```
┌─────────────────────────────────────────────┐
│          Internet (HTTPS/443)               │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│          Nginx Reverse Proxy                │
│       (SSL Termination, Load Balancing)     │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            JupyterHub (Port 8000)           │
│   ┌─────────────────────────────────────┐   │
│   │  PAM Authenticator                  │   │
│   │  (Email + Password)                 │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  User 1: student1@dhbw.de           │   │
│   │  → JupyterLab Instance              │   │
│   │  → CPU: 1 core, RAM: 2GB            │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  User 2: student2@dhbw.de           │   │
│   │  → JupyterLab Instance              │   │
│   │  → CPU: 1 core, RAM: 2GB            │   │
│   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Parameter

### Pflichtparameter

- **`student_emails`**: Liste der Studierenden (1-30 Emails)
- **`admin_email`**: Dozenten-Email für Admin-Zugang

### Optional

- **`cpu_cores`**: 2-16 (Standard: 4)
- **`ram_mb`**: 4096-32768 (Standard: 8192)
- **`disk_gb`**: 20-500 (Standard: 50)
- **`enable_gpu`**: GPU-Support aktivieren (Standard: false)
- **`python_packages`**: Zusätzliche Pakete installieren
- **`enable_git_sync`**: Git-Repository automatisch synchronisieren
- **`git_repo_url`**: URL des Übungsrepositorys

## Deployment-Beispiel

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
    "cpu_cores": 8,
    "ram_mb": 16384,
    "disk_gb": 100,
    "python_packages": [
      "pandas",
      "numpy",
      "matplotlib",
      "scikit-learn",
      "tensorflow",
      "torch"
    ],
    "enable_git_sync": true,
    "git_repo_url": "https://github.com/dhbw/ml-exercises.git"
  }
}
```

## Outputs

### Nicht-Sensibel

- `jupyterhub_url`: Login-URL (z.B. `https://203.0.113.42`)
- `server_info`: VM-Details, Ressourcen
- `installed_packages`: Liste der Python-Pakete
- `access_instructions`: Anleitung für Studierende

### Sensibel (via `/deployments/{id}/keys`)

- `admin_credentials`: Admin Login + API-Token
- `student_credentials`: Passwörter für jeden Studierenden
- `ssh_private_key`: SSH-Zugang für Server-Administration

## Zugriff

### Studierende

1. URL öffnen: `https://<floating-ip>`
2. Login mit Email + Passwort (aus `student_credentials`)
3. JupyterLab Interface öffnet sich automatisch

### Administrator

1. Login als Admin mit `admin_email` + `admin_password`
2. Zugriff auf alle User-Notebooks
3. API-Token für Automatisierung verfügbar

## Resource Allocation

Ressourcen werden **fair zwischen allen Usern aufgeteilt**:

```python
# Beispiel: 8 CPU Cores, 16GB RAM, 10 Studierende
cpu_per_user = 8 / 10 = 0.8 cores
ram_per_user = 16384 / 10 = 1638 MB
```

## Mock-Modus Testing

```bash
cd terraform
terraform init
terraform workspace new test-jupyter
terraform apply \
  -var="use_mock_provider=true" \
  -var='student_emails=["test1@example.com","test2@example.com"]' \
  -var="admin_email=admin@example.com"
```

Erstellt:
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