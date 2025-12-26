---
title: "The Render CLI – Render Docs"
description: ""
author: ""
url: "https://render.com/docs/cli"
date: ""
date_accessed: "2025-12-26T18:11:28Z"
firecrawl_id: "019b5bdb-c2a6-704b-adb5-fd2bf1c558e4"
---
Use the Render CLI to manage your Render services and datastores directly from your terminal:

Among many other capabilities, the CLI supports:

- Triggering service deploys, restarts, and one-off jobs
- Opening a psql session to your database
- Viewing and filtering live service logs

The CLI also supports [non-interactive use](https://render.com/docs/cli#non-interactive-mode) in scripts and CI/CD.

Please submit bugs and feature requests on the CLI's [public GitHub repository](https://github.com/render-oss/cli).

## Setup

### 1\. Install

Homebrew

Linux/MacOS

Direct download

Build from source

Run the following commands:

shellCopy to clipboard

```shell
$ brew update
$ brew install render
```
Run the following command:

shellCopy to clipboard

```shell
$ curl -fsSL https://raw.githubusercontent.com/render-oss/cli/refs/heads/main/bin/install.sh | sh
```
1. Open the CLI's [GitHub releases page](https://github.com/render-oss/cli/releases/).
2. Download the executable that corresponds to your system's architecture.

If you use an architecture besides those provided, you can build from source instead.

We recommend building from source only if no other installation method works for your system.

1. [Install the Go programming language](https://golang.org/doc/install) if you haven't already.

2. Clone and build the CLI project with the following commands:

shellCopy to clipboard

```shell
$ git clone git@github.com:render-oss/cli.git
$ cd cli
$ go build -o render
```
After installation completes, open a new terminal tab and run `render` with no arguments to confirm.

### 2\. Log in

The Render CLI uses a **CLI token** to authenticate with the Render platform. Generate a token with the following steps:

1. Run the following command:

shellCopy to clipboard

```shell
$ render login
```
Your browser opens a confirmation page in the Render Dashboard.

2. Click **Generate token**.

The CLI saves the generated token to its [local configuration file](https://render.com/docs/cli#local-config).

3. When you see the success message in your browser, close the tab and return to your terminal.

4. The CLI prompts you to set your active workspace.

You can switch workspaces at any time with `render workspace set`.

You're ready to go!

## Common commands

**This is not an exhaustive list of commands.**

- Run `render` with no arguments for a list of all available commands.
- Run `render help <command>` for details about a specific command.

| Command | Description |
| --- | --- |
| `login` | Opens your browser to authorize the Render CLI for your account. Authorizing generates a CLI token that's saved locally.<br>If the CLI already has a valid CLI token or [API key](https://render.com/docs/cli#1-authenticate-via-api-key), this command instead exits with a zero status. |
| `workspace set` | Sets the CLI's active workspace. CLI commands always operate on the active workspace. |
| `services` | Lists all services and datastores in the active workspace. Select a service to perform actions like deploying, viewing logs, or opening an SSH/psql session. |
| `deploys list`<br>`[SERVICE_ID]` | Lists deploys for the specified service. Select a deploy to view its logs or open its details in the Render Dashboard.<br>If you don't provide a service ID in interactive mode, the CLI prompts you to select a service. |
| `deploys create`<br>`[SERVICE_ID]` | Triggers a deploy for the specified service.<br>If you don't provide a service ID in interactive mode, the CLI prompts you to select a service.<br>In [non-interactive mode](https://render.com/docs/cli#non-interactive-mode), helpful options include:<br>- `--wait` to block until the deploy completes (a failed deploy exits with a non-zero status)<br>- `--commit [SHA]` to deploy a specific commit (Git-backed services only)<br>- `--image [URL]` to deploy a specific Docker image tag or digest (image-backed services only) |
| `psql`<br>`[DATABASE_ID]` | Opens a psql session to the specified PostgreSQL database.<br>If you don't provide a database ID in interactive mode, the CLI prompts you to select a database. |
| `ssh`<br>`[SERVICE_ID]` | Opens an SSH session to a running instance of the specified service.<br>If you don't provide a service ID in interactive mode, the CLI prompts you to select a service. |

## Non-interactive mode

By default, the Render CLI uses interactive, menu-based navigation. This default is great for manual use, but not for scripting or automation.

Configure the CLI for non-interactive use in CI/CD and other automated environments with the following steps:

### 1\. Authenticate via API key

The Render CLI can authenticate using an API key instead of [`render login`](https://render.com/docs/cli#2-log-in). Unlike CLI tokens, API keys do not periodically expire. For security, use this authentication method only for automated environments.

1. Generate an API key with [these steps](https://render.com/docs/api#1-create-an-api-key).

2. In your automation's environment, set the `RENDER_API_KEY` environment variable to your API key:

bashCopy to clipboard

```bash
export RENDER_API_KEY=rnd_RUExip…
```
If you provide an API key this way, it always takes precedence over CLI tokens you generate with `render login`.

### 2\. Set non-interactive command options

Set the following options for _all_ commands you run in non-interactive mode:

| Flag | Description |
| --- | --- |
| ###### `-o` / `--output` | Sets the output format. For automated environments, specify `json` or `yaml`.<br>Also supports `text` for unstructured text output, along with the default value `interactive`. |
| ###### `--confirm` | Skips any confirmation prompts that the command would otherwise display. |

For example, to list the active workspace's services in JSON format:

shellCopy to clipboard

```shell
$ render services --output json --confirm
```
### Example: GitHub Actions

This example action provides similar functionality to Render's [automatic Git deploys](https://render.com/docs/deploys#automatic-git-deploys). You could disable auto-deploys and customize this action to trigger deploys with different conditions.

To use this action, first set the following secrets in your repository:

| Secret | Description |
| --- | --- |
| `RENDER_API_KEY` | A valid Render [API key](https://render.com/docs/api#1-create-an-api-key) |
| `RENDER_SERVICE_ID` | The ID of the service you want to deploy |

yamlCopy to clipboard

```yaml
name: Render CLI Deploy
run-name: Deploying via Render CLI
# Run this workflow when code is pushed to the main branch.
on:
  push:
    branches:
      - main
jobs:
  Deploy-Render:
    runs-on: ubuntu-latest
    steps:
      # Downloads the Render CLI binary and adds it to the PATH.
      # To prevent breaking changes in CI/CD, we pin to a
      # specific CLI version (in this case 1.1.0).
      - name: Install Render CLI
        run: |
          curl -L https://github.com/render-oss/cli/releases/download/v1.1.0/cli_1.1.0_linux_amd64.zip -o render.zip
          unzip render.zip
          sudo mv cli_v1.1.0 /usr/local/bin/render
      - name: Trigger deploy with Render CLI
        env:
          # The CLI can authenticate via a Render API key without logging in.
          RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
          CI: true
        run: |
          render deploys create ${{ secrets.RENDER_SERVICE_ID }} --output json --confirm
```
## Local config

By default, the Render CLI stores its local configuration at the following path:

plaintextCopy to clipboard

```
$HOME/.render/cli.yaml
```
You can change this file path by setting the `RENDER_CLI_CONFIG_PATH` environment variable.

## Managing CLI tokens

For security, CLI tokens periodically expire. If you don't use the Render CLI for a while, you might need to re-authenticate with `render login`.

View a list of your active CLI tokens from your [Account Settings page](https://dashboard.render.com/u/settings#render-cli-tokens) in the Render Dashboard. You can manually revoke a CLI token that you no longer need or that might be compromised. Expired and revoked tokens tokens do not appear in the list.

Copy page

###### [The Render CLI](https://render.com/docs/cli)

- [Setup](https://render.com/docs/cli#setup)
  - [1\. Install](https://render.com/docs/cli#1-install)
  - [2\. Log in](https://render.com/docs/cli#2-log-in)
- [Common commands](https://render.com/docs/cli#common-commands)
- [Non-interactive mode](https://render.com/docs/cli#non-interactive-mode)
  - [1\. Authenticate via API key](https://render.com/docs/cli#1-authenticate-via-api-key)
  - [2\. Set non-interactive command options](https://render.com/docs/cli#2-set-non-interactive-command-options)
  - [Example: GitHub Actions](https://render.com/docs/cli#example-github-actions)
- [Local config](https://render.com/docs/cli#local-config)
- [Managing CLI tokens](https://render.com/docs/cli#managing-cli-tokens)

Did this page help?

![AI assistant avatar](https://render.com/images/render-logo-white.png)

AI assistant

# Ready to help.

Usage policy

### Example prompts

Add a custom domain

Describe service types

Restrict external access to database

Set Node.js version

Powered byTag Line Logo Icon [inkeep](https://www.inkeep.com/)

[Render Community](https://community.render.com/)
