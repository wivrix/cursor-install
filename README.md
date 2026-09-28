# cursor-install

Install the Cursor CLI on a new machine and configure it in one command:

- installs the Cursor agent
- `cursor` starts the agent (no IDE install required)
- approval mode is **Run Everything** (`unrestricted`, the same as `--yolo`)
- adds `~/.local/bin` to your shell startup files (`~/.bashrc`, `~/.profile`, and `~/.zshrc` when you use zsh)
- when `/usr/local/bin` is writable (including root), links `agent` and `cursor` there so the current shell can run them immediately

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/wivrix/cursor-install/main/install-now.sh | bash
```

Sign in once:

```bash
agent login
```

If that shell was already open and `agent` is still not found, either run the installer again or load the new PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
agent login
```

After that, start the agent with:

```bash
cursor
```

`agent` is the same program. `cursor agent` works too.

## What the script changes

| Item | Result |
| --- | --- |
| Cursor CLI | Official installer from `https://cursor.com/install` |
| Start command | `~/.local/bin/cursor` launches the agent |
| Approval mode | Run Everything (`approvalMode: unrestricted` in `~/.cursor/cli-config.json`) |
| Shell | `~/.local/bin` on `PATH` in bash and, when present, zsh |
| Default PATH | `agent` and `cursor` linked into `/usr/local/bin` when that directory is writable |

The script does not copy API keys or account data. Sign-in stays on the new machine (`agent login`).

Running it again is safe. Existing shell PATH lines and an existing CLI config are kept; approval mode is set to Run Everything and the `cursor` launcher is rewritten so it still starts the agent.

## Manual run

```bash
git clone https://github.com/wivrix/cursor-install.git
cd cursor-install
./install.sh
```

## Requirements

macOS or Linux, with `curl` and `python3`.
