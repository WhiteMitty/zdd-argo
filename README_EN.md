<p align="right">
  <a href="./README.md"><kbd>简体中文</kbd></a>
  <a href="./README_EN.md"><kbd><strong>English</strong></kbd></a>
</p>

# zdd-argo

A bilingual interactive script for deploying and managing **Cloudflare Quick Tunnel + VMess/WS** on Debian and Ubuntu VPS servers.

> Current version: **v 0.1.0**

`zdd-argo` installs script-managed copies of `sing-box` and `cloudflared`, keeps the temporary Argo tunnel running inside a background `tmux` session, and generates a VMess share link. The tunnel continues running after the SSH session is disconnected.

## Features

- Select the interface language at startup:
  - `1) 中文`
  - `2) English`
- Only one management command is required after installation:

  ```bash
  zdd argo
  ```

- Installs and updates script-managed copies of:
  - `sing-box`
  - `cloudflared`
- Downloads core programs from official GitHub Releases and verifies SHA-256 digests
- Makes `sing-box` listen only on `127.0.0.1:10000`
- Runs Cloudflare Quick Tunnel in a dedicated background `tmux` session
- Automatically generates a UUID, WebSocket path, and VMess share link
- Fixes the share-link name to:

  ```text
  zdd-argo
  ```

- Supports a preferred endpoint as:
  - Domain name
  - IPv4 address
  - IPv6 address
- Default preferred domain:

  ```text
  saas.sin.fan
  ```

- Supports viewing the subscription, checking status, updating both core programs, clearing temporary data, and safe uninstallation
- Does not overwrite `sing-box` or `cloudflared` installations managed by apt or other projects

## Requirements

- Debian or Ubuntu
- systemd
- Root privileges
- Supported CPU architectures:
  - `amd64`
  - `arm64`
- Network access to GitHub and Cloudflare

## Installation

Run as root. Non-root users may add `sudo` before the final command.

### curl

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

### wget

```bash
wget -qO zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

On the first run, the script will:

1. Ask you to select Chinese or English;
2. Check the operating system and required packages;
3. Install a managed script copy at:

   ```text
   /usr/local/lib/zdd-argo/zdd-argo.sh
   ```

4. Create the launcher:

   ```text
   /usr/local/bin/zdd
   ```

5. Ask for a preferred domain or preferred IP;
6. Open the management menu.

After installation, run only:

```bash
zdd argo
```

The downloaded `zdd-argo.sh` file may be kept, moved, or deleted without affecting the installed launcher.

## Language Selection

Every time you run:

```bash
zdd argo
```

the script first displays:

```text
Select language / 选择语言
1) 中文
2) English
```

The selected language is used for the menu, prompts, status output, and error messages during that session.

## Preferred Domain / Preferred IP

On first run, the script shows:

```text
Default: saas.sin.fan
```

This default domain is intended mainly for **China Telecom routes in mainland China**. It is not guaranteed to perform better on other carriers or in other regions. Other users should enter a preferred domain or IP suitable for their own route.

Accepted examples:

```text
example.com
104.16.1.1
2606:4700:4700::1111
```

Press Enter to retain the current value. During the first configuration, pressing Enter selects the default.

The preferred endpoint can also be changed later from the main menu. Changing it does not restart the running temporary Argo tunnel; it only regenerates the share link.

## Management Menu

```text
1. Generate / manage temporary Argo
2. View current subscription
3. Set preferred domain / preferred IP
4. Update core components
5. View status and recent logs
6. Disconnect current Argo and clear temporary cache
7. Uninstall zdd-argo (keep sing-box and cloudflared)
8. Full uninstall (including script-managed sing-box and cloudflared)
0. Exit
```

Exiting the menu does not stop the running temporary Argo tunnel.

### Updating Core Components

The update submenu provides:

```text
1. Update sing-box
2. Update cloudflared
3. Update both sing-box and cloudflared
0. Back
```

Updating `cloudflared` does not interrupt the currently running tunnel. The new version is used the next time the temporary Argo tunnel is rebuilt.

## Share-Link Parameters

The generated VMess share link uses:

| Field | Value |
|---|---|
| Node name | `zdd-argo` |
| Address | Current preferred domain or preferred IP |
| Port | `443` |
| Transport | `WebSocket` |
| TLS | Enabled |
| Host | Current temporary `trycloudflare.com` hostname |
| SNI | Current temporary `trycloudflare.com` hostname |
| ALPN | `http/1.1` |
| Fingerprint | `firefox` |
| Local inbound | `127.0.0.1:10000` |

Before saving the link, the script decodes and validates the VMess JSON to confirm that:

- The name is `zdd-argo`
- The preferred endpoint is correct
- Host and SNI match the temporary hostname
- ECH extension fields are present

## ECH Compatibility

The script writes both:

```text
ech
echConfigList
```

Default value:

```text
cloudflare-ech.com+https://dns.jhb.ovh/joeyblog
```

Client support for extension fields in legacy VMess JSON varies. After importing the link, verify `EchConfigList`. If the client does not preserve it, paste the value manually.

## File Locations

| Path | Purpose |
|---|---|
| `/usr/local/lib/zdd-argo/zdd-argo.sh` | Managed script copy |
| `/usr/local/lib/zdd-argo/sing-box` | Script-managed sing-box |
| `/usr/local/lib/zdd-argo/cloudflared` | Script-managed cloudflared |
| `/usr/local/bin/zdd` | Main `zdd argo` launcher |
| `/usr/local/sbin/zdd` | Compatibility launcher |
| `/etc/zdd-argo/settings.json` | Preferred endpoint setting |
| `/etc/zdd-argo/state.json` | UUID, WebSocket path, and temporary hostname state |
| `/etc/zdd-argo/vmess.json` | Current VMess JSON |
| `/etc/zdd-argo/vmess.txt` | Current VMess share link |
| `/var/log/zdd-argo-cloudflared.log` | cloudflared log |
| `/etc/systemd/system/zdd-argo-singbox.service` | sing-box systemd service |

Do not upload the following runtime files to GitHub:

```text
/etc/zdd-argo/settings.json
/etc/zdd-argo/state.json
/etc/zdd-argo/vmess.json
/etc/zdd-argo/vmess.txt
```

## Security Design

The GitHub edition preserves and extends the security controls from the local stable version:

- Does not use `curl | sh` to install `sing-box`
- Downloads binaries from official GitHub Releases
- Verifies GitHub-provided SHA-256 digests
- Validates Release asset URL origins
- Checks the sing-box archive for path traversal before extraction
- Uses a dedicated installation directory and does not overwrite system-managed programs
- Rolls back `sing-box` if an update fails
- Rolls back `cloudflared` if an update fails
- Rechecks service recovery after a sing-box rollback
- Makes sing-box listen only on loopback
- Applies systemd hardening directives
- Parses state as JSON instead of executing state-file content
- Uses a write-operation lock
- Prevents the background tmux process from inheriting that lock
- Does not remove an unknown same-named launcher
- Does not delete downloaded files or Git working-tree files during uninstall
- Self-validates generated share links

## Updating the Script

Download and run the latest script again:

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

This updates:

```text
/usr/local/lib/zdd-argo/zdd-argo.sh
```

Updating the script itself does not stop the current temporary Argo tunnel.

## Uninstallation

Run:

```bash
zdd argo
```

Then choose:

```text
7. Uninstall zdd-argo (keep sing-box and cloudflared)
```

or:

```text
8. Full uninstall (including script-managed sing-box and cloudflared)
```

The normal uninstall keeps the script-managed `sing-box` and `cloudflared`. The full uninstall removes them as well.

Neither option deletes:

- A manually downloaded `zdd-argo.sh`
- Files in a Git clone
- Same-named programs managed by apt or other projects

## Quick Tunnel Notes

This project uses Cloudflare Quick Tunnel, which generates a random:

```text
*.trycloudflare.com
```

hostname.

Important limitations:

- The previous hostname becomes invalid after the tunnel is stopped or rebuilt
- A new temporary tunnel must be created after a VPS restart or cloudflared exit
- Quick Tunnel is positioned for development and testing
- Cloudflare currently documents a concurrent request limit and no SSE support
- It should not be treated as a production tunnel with an SLA

Official Cloudflare documentation:

- [Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
- [Set up Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/setup/)

## FAQ

### Why does `zdd argo` not open the menu?

Check the launcher files:

```bash
ls -l /usr/local/bin/zdd /usr/local/sbin/zdd
```

Then run:

```bash
command -v zdd
```

The expected result is:

```text
/usr/local/bin/zdd
```

or:

```text
/usr/local/sbin/zdd
```

If another program already owns a `zdd` launcher path, the installer stops with a clear warning instead of overwriting it.

### Why is `zdd argo` the only command?

This is intentional. The public edition does not expose multiple complex subcommands; all operations are available from the interactive menu.

### Why is the share-link name not configurable?

The project fixes the name to:

```text
zdd-argo
```

The generated link is self-validated and is not saved if the name is wrong.

### Why did an old subscription stop working?

Quick Tunnel hostnames are temporary. Recreate and reimport the share link after a tunnel stop, rebuild, or VPS restart.

### Does the tunnel stop when SSH disconnects?

No. `cloudflared` runs in a dedicated background `tmux` session.

### Does exiting the menu stop the tunnel?

No. The menu process and temporary Argo tunnel have independent lifecycles.

## License

This project is licensed under the [MIT License](LICENSE).

## Disclaimer

This project is intended only for lawful network testing, learning, and personal administration. Users must comply with local laws, Cloudflare's terms of service, and the policies of relevant service providers. The author is not responsible for misuse, configuration errors, service interruptions, or resulting losses.
