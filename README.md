# cursor-install

Install the Cursor CLI on a new machine and configure it in one command:

- installs the Cursor agent
- `cursor` starts the agent (no IDE install required)
- approval mode is **Run Everything** (`unrestricted`, the same as `--yolo`)
- adds `~/.local/bin` to your shell startup files (`~/.bashrc`, `~/.profile`, and `~/.zshrc` when you use zsh)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/wivrix/cursor-install/main/install.sh | bash
```

Open a new terminal, then sign in once:

```bash
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
