# Security Policy

## Scope and threat model

MCP Shell Server is a development tool. It exposes a `run_command` tool that executes arbitrary shell commands inside a Docker container, and **it has no built-in authentication by design**: anyone who can reach the endpoint can run commands in the container. The setup described in the README relies on keeping the ngrok URL secret, so please read the [Security Considerations](README.md#security-considerations) section before exposing it.

Reports that only restate this design (for example, "an unauthenticated client can run commands") are expected behavior of the default setup. Improvements to it, such as built-in authentication or safer defaults, are welcome as issues or pull requests.

## Supported versions

This project has no tagged releases. Only the latest commit on the `main` branch is maintained.

## Reporting a vulnerability

Please **do not open a public issue** for a vulnerability. Report it privately through GitHub:

1. Go to the [Security tab](https://github.com/CristianValverde/mcp-shell-server/security) of this repository.
2. Click **Report a vulnerability**.

Please include:

- a description of the issue and its impact;
- steps to reproduce it;
- the affected file or component;
- a suggested fix, if you have one.

## What to expect

This is a personal project maintained on a best-effort basis. I will try to acknowledge a report within a week, agree on a fix and a disclosure date with you, and credit you in the fix if you wish.
