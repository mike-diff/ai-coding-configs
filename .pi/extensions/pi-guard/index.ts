/**
 * pi-guard — safety parity with the Claude Code / Cursor hooks.
 *
 * Ports the enforcement semantics of `.claude/hooks/block-dangerous.sh`,
 * `validate-commit.sh`, and `redact-secrets.sh` to pi's extension API:
 * `tool_call` events that block dangerous bash commands, non-conventional
 * commit messages, and reads of secret-bearing files. Same patterns, same
 * reason strings, same fail-open rules — when the patterns here change,
 * change the .claude and .cursor hooks to match (see tests/workflow-contract.sh).
 *
 * Loaded project-scope from `.pi/extensions/` (after trust) or user-scope via
 * the package manifest in the repo root package.json (`pi install`).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { basename } from "node:path";

const COMMIT_TYPES = "feat|fix|refactor|docs|test|chore|style|perf|ci|revert";
const COMMIT_PATTERN = new RegExp(`^(${COMMIT_TYPES})(\\([a-zA-Z0-9_-]+\\))?!?: .+`);

/** Destructive shell commands — mirrors block-dangerous.sh. */
function dangerousCommandReason(command: string): string | undefined {
  if (/\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive.*--force|-[a-zA-Z]*f[a-zA-Z]*r)\s+(\/|~|\.\.|\.(\/\.\.)?)(\s|$)/.test(command)) {
    return "Blocked: Recursive force-delete on a broad path. Use a more specific path or remove files individually.";
  }
  if (/git\s+push\s+.*--force.*\s+(main|master)(\s|$)/.test(command) ||
      /git\s+push\s+.*\s-f\s+.*\s+(main|master)(\s|$)/.test(command)) {
    return "Blocked: Force push to main/master is not allowed. Use a feature branch instead.";
  }
  if (/git\s+reset\s+--hard/.test(command)) {
    return "Blocked: Hard reset discards uncommitted changes. Use 'git stash' or commit your changes first.";
  }
  if (/(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)/i.test(command)) {
    return "Blocked: Destructive SQL operation (DROP/TRUNCATE). Verify the command manually before running.";
  }
  if (/delete\s+from\s+\w+\s*;?\s*$/i.test(command)) {
    return "Blocked: DELETE without WHERE clause. Add a WHERE condition to avoid deleting all rows.";
  }
  return undefined;
}

/** Conventional-commit validation — mirrors validate-commit.sh. */
function badCommitReason(command: string): string | undefined {
  if (!/git\s+commit/.test(command) || !/(-m|--message)\b/.test(command)) {
    return undefined; // not a commit with a message flag — allow
  }
  const doubleQuoted = command.match(/(?:-m|--message)\s+"([^"]*)"/);
  const singleQuoted = doubleQuoted ?? command.match(/(?:-m|--message)\s+'([^']*)'/);
  const message = singleQuoted?.[1];
  if (message === undefined || message === "") {
    return undefined; // heredoc or unparseable — allow, like the hook
  }
  if (!COMMIT_PATTERN.test(message)) {
    return `Blocked: commit message must match 'type(scope): description'. Valid types: ${COMMIT_TYPES.replace(/\|/g, ", ")}. Example: 'feat(auth): add JWT token refresh'. Please fix the commit message and retry.`;
  }
  return undefined;
}

/** Sensitive filenames — mirrors redact-secrets.sh. */
function sensitiveFileNameReason(path: string): string | undefined {
  const name = basename(path);
  if (/^\.env(\.|$)/.test(name)) {
    return `Blocked: ${name} looks like an env file and was not sent to the model.`;
  }
  if (["credentials.json", "service-account.json", "id_rsa", "id_ed25519"].includes(name) ||
      name.endsWith(".pem") || name.endsWith(".key")) {
    return `Blocked: ${name} is a credentials/key file and was not sent to the model.`;
  }
  return undefined;
}

/** High-confidence secret patterns in file content — mirrors redact-secrets.sh. */
async function secretContentReason(path: string): Promise<string | undefined> {
  try {
    const content = (await readFile(path)).subarray(0, 50_000).toString("utf8");
    if (/AKIA[0-9A-Z]{16}/.test(content)) {
      return "Blocked: file contains what appears to be an AWS access key.";
    }
    if (/(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}/.test(content)) {
      return "Blocked: file contains what appears to be a GitHub token.";
    }
    if (/-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(content)) {
      return "Blocked: file contains a private key.";
    }
    if (/xox[bpors]-[0-9a-zA-Z-]{10,}/.test(content)) {
      return "Blocked: file contains what appears to be a Slack token.";
    }
  } catch {
    // Missing/unreadable file — allow, like the hook (fail-open on scanning).
  }
  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (event.toolName === "bash") {
      const command = (event.input as { command?: string }).command ?? "";
      const reason = dangerousCommandReason(command) ?? badCommitReason(command);
      if (reason) return { block: true, reason };
    }
    if (event.toolName === "read") {
      const path = (event.input as { path?: string }).path ?? "";
      const nameReason = sensitiveFileNameReason(path);
      if (nameReason) return { block: true, reason: nameReason };
      const contentReason = await secretContentReason(path);
      if (contentReason) return { block: true, reason: contentReason };
    }
    return undefined;
  });
}
