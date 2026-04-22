# MCP Shell Server — Remote AI Agent over Docker + ngrok

Run Claude (or any MCP-compatible AI) as a **fully autonomous remote dev agent** on your local machine — execute shell commands, run tests, and work with any tool in your container from anywhere, without deploying anything to the cloud.

---

## The Problem

You want Claude (via Cowork or Claude Code) to execute commands on your local machine — run tests, execute Python scripts, trigger builds — while you're away. The standard MCP setup only works locally. This solves that.

---

## Architecture

```
You (remote, any device)
        ↓
  Claude / Cowork / any MCP client
        ↓
  ngrok static domain (HTTPS, permanent URL)
        ↓
  Your machine (Windows/Linux/macOS)
        ↓
  Docker container
        ↓
  MCP Shell Server (port 8765)
        ↓
  Your project + all its dependencies
```

The MCP server lives **inside the Docker container** — same environment, same dependencies, zero extra setup. ngrok tunnels it to the internet with a permanent static URL.

---

## Why This Approach

- **No cloud deployment** — your project stays on your machine
- **No domain purchase required** — ngrok free tier includes one static domain
- **Zero maintenance** — Docker restarts automatically, ngrok starts at login (no terminal window needed)
- **Full environment parity** — Claude runs commands in the exact same env as your project

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [ngrok](https://ngrok.com/download) installed (free account)
- A project with a `Dockerfile`
- Claude desktop app with [Cowork](https://claude.ai), or any MCP-compatible client

---

## Setup

### Step 1 — Add the MCP server to your project

Copy `mcp_server.py` and `start.sh` to your project root.

`mcp_server.py` exposes a single tool — `run_command` — that executes shell commands inside the container with a 5-minute timeout.

`start.sh` launches both your app and the MCP server in parallel when the container starts. Edit the "your app" section to match your project.

### Step 2 — Update your Dockerfile

Add to your `requirements.txt`:
```
mcp>=1.0
uvicorn>=0.30
```

Then in your `Dockerfile` (see `Dockerfile.example` for a full template):
```dockerfile
EXPOSE 8765   # MCP server port (add alongside your existing ports)

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
```

### Step 3 — Run your container with auto-restart and port 8765 exposed

```bash
docker run -d \
    --name your-container-name \
    --restart=always \
    -p 8765:8765 \
    -p 8888:8888 \
    -v "$(pwd):/app" \
    your-image-name
```

The `--restart=always` flag ensures the container comes back up automatically after a reboot.

### Step 4 — Get your ngrok static domain

1. Create a free account at [ngrok.com](https://ngrok.com)
2. Go to [dashboard.ngrok.com/domains](https://dashboard.ngrok.com/domains) → **New Domain**
3. ngrok gives you one free static domain (e.g. `your-name.ngrok-free.dev`)

### Step 5 — Configure ngrok

Copy `ngrok.yml.example` to `ngrok.yml` and fill in your values:

```yaml
version: "3"
agent:
  authtoken: YOUR_NGROK_AUTHTOKEN
tunnels:
  mcp-shell:
    proto: http
    addr: 8765
    domain: your-name.ngrok-free.dev
    host_header: rewrite   # required — prevents "Invalid Host header" errors
```

> ⚠️ **Never commit `ngrok.yml`** — it contains your authtoken. It's already in `.gitignore`.

### Step 6 — Set up ngrok to auto-start at Windows login (no terminal window)

Run `setup_ngrok_task.bat` **as Administrator** (right-click → Run as administrator). This registers a Windows Scheduled Task that launches ngrok silently at every login — no terminal window required.

```
Right-click setup_ngrok_task.bat → Run as administrator
```

> You only need to do this once. For Linux/macOS, use a systemd service or add the equivalent to your login scripts.

**Important: the task runs at the next login, not immediately.** To activate ngrok right now without logging out, use one of these methods:

**Option A — trigger the scheduled task directly:**
```powershell
schtasks /run /tn "ngrok-mcp-tunnel"
```

**Option B — launch ngrok in the background manually:**
```powershell
Start-Process ngrok -ArgumentList "start --all --config `"C:\path\to\your\project\ngrok.yml`"" -WindowStyle Hidden
```

Either way, closing PowerShell won't kill ngrok — it runs as a detached background process.

**Verify ngrok is running:**
```powershell
Invoke-RestMethod http://localhost:4040/api/tunnels | ConvertTo-Json
```
You should see your tunnel URL in the output. Also check [dashboard.ngrok.com/endpoints](https://dashboard.ngrok.com/endpoints).

### Step 7 — Connect Claude

Add a new MCP connector in Cowork (or your MCP client) with this URL:

```
https://your-name.ngrok-free.dev/sse
```

> ⚠️ The `/sse` suffix is required. Without it, the connection will fail.

That's it. Claude now has a `run_command` tool that executes directly inside your container.

---

## Files

| File | Purpose |
|------|---------|
| `mcp_server.py` | MCP shell server (FastMCP + uvicorn, port 8765) |
| `start.sh` | Container entrypoint — starts your app + MCP server in parallel |
| `Dockerfile.example` | Dockerfile template showing how to integrate the MCP server |
| `ngrok.yml.example` | ngrok config template (copy to `ngrok.yml` and fill in credentials) |
| `setup_ngrok_task.bat` | Windows script to register ngrok as a startup task (run once as admin) |

---

## How It Works Day-to-Day

1. You turn on your PC → Docker Desktop auto-starts → container restarts → ngrok starts automatically (no window, no terminal)
2. You open Claude from your phone, tablet, or any device
3. Claude connects to your machine via the MCP connector
4. You ask Claude to run tests, execute scripts, debug code — it all runs on your machine in your container

---

## Security Considerations

- **Your ngrok URL gives shell access to your container.** Treat it like a private API key — do not share it publicly.
- The MCP server runs inside Docker, so it can only access what you explicitly mount into the container.
- ngrok free plan: 1 static domain, 1 concurrent session, 20k requests/month — generous for dev use.
- For extra security, add IP restrictions in the ngrok dashboard (Endpoints → your domain → IP Restrictions).

---

## Limitations

- Requires your PC to be **on and connected to the internet**.
- On Windows, the MSIX version of ngrok (from the Microsoft Store) doesn't support running as a Windows Service — the Scheduled Task approach used here is the reliable alternative.
- `run_command` executes commands inside the Linux container, not on the Windows host. For Windows-specific tasks, use Cowork's computer use tools.

---

## Troubleshooting

**"Couldn't reach the MCP server"**
→ Check that ngrok is running: `Get-Process ngrok` (PowerShell) or visit [dashboard.ngrok.com/endpoints](https://dashboard.ngrok.com/endpoints)
→ Verify the tunnel is active: `Invoke-RestMethod http://localhost:4040/api/tunnels`
→ Check the container is running: `docker ps`
→ Make sure the connector URL ends in `/sse`
→ Reconnect the MCP connector in Cowork (Settings → Connectors) — SSE sessions don't auto-recover after the tunnel drops

**ngrok not running after setup_ngrok_task.bat**
→ The scheduled task runs at login, not immediately after creation
→ Trigger it now: `schtasks /run /tn "ngrok-mcp-tunnel"`
→ Or start it in the background: `Start-Process ngrok -ArgumentList "start --all --config ..." -WindowStyle Hidden`
→ Verify the task exists: `schtasks /query /tn "ngrok-mcp-tunnel"`

**Closing PowerShell killed ngrok**
→ ngrok was started in the foreground. Always use the scheduled task or `Start-Process ... -WindowStyle Hidden` to run it detached from any terminal window.

**"Invalid Host header"**
→ Make sure `host_header: rewrite` is present in your `ngrok.yml`

**ngrok ignores the config file / uses wrong port**
→ Always pass the config explicitly: `ngrok start --all --config path\to\ngrok.yml`

**Container not restarting after reboot**
→ Make sure Docker Desktop is configured to start with Windows (Settings → General → Start Docker Desktop when you sign in)
→ Verify the container was started with `--restart=always`: `docker inspect your-container-name | findstr RestartPolicy`
