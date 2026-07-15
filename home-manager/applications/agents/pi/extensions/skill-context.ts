import * as fs from "node:fs";
import {
  type ExtensionAPI,
  getAgentDir,
  loadSkills,
  parseFrontmatter,
  resolveCliModel,
  stripFrontmatter,
} from "@earendil-works/pi-coding-agent";

const FORKED_SKILL_TIMEOUT_MS = 10 * 60 * 1000;

export function parseSkillCommand(text: string): { name: string; args: string } | null {
  const m = text.trim().match(/^\/skill:([a-z0-9][a-z0-9-]*)(?:\s+([\s\S]*))?$/);
  if (!m) return null;
  return { name: m[1], args: m[2]?.trim() ?? "" };
}

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    const cmd = parseSkillCommand(event.text);
    if (!cmd) return;

    const { skills } = loadSkills({
      cwd: ctx.cwd,
      agentDir: getAgentDir(),
      skillPaths: [],
      includeDefaults: true,
    });
    const skill = skills.find((s) => s.name === cmd.name);
    if (!skill) return;

    let content: string;
    try {
      content = fs.readFileSync(skill.filePath, "utf-8");
    } catch {
      return;
    }
    const { frontmatter } = parseFrontmatter<Record<string, unknown>>(content);
    if (frontmatter.context !== "fork") return;

    const modelRef = resolveClosestModel(frontmatter.model, ctx);
    if (modelRef === undefined && typeof frontmatter.model === "string" && ctx.hasUI) {
      ctx.ui.notify(
        `skill-context: no model matches "${frontmatter.model}" — using current model`,
        "warning",
      );
    }

    let prompt =
      `${stripFrontmatter(content).trim()}\n\n` +
      `(Skill directory: ${skill.baseDir} — resolve relative paths in the skill against it.)`;
    if (cmd.args) prompt += `\n\nUser: ${cmd.args}`;

    const args = ["-p", "--no-session"];
    if (modelRef) args.push("--model", modelRef);
    args.push(prompt);

    if (ctx.hasUI) {
      ctx.ui.notify(`Forking skill "${skill.name}"${modelRef ? ` on ${modelRef}` : ""}…`, "info");
    }

    const result = await pi.exec("pi", args, {
      timeout: FORKED_SKILL_TIMEOUT_MS,
      signal: ctx.signal,
    });

    if (result.killed || result.code !== 0) {
      const reason = result.killed ? "timed out" : `exited with code ${result.code}`;
      if (ctx.hasUI) ctx.ui.notify(`Forked skill "${skill.name}" ${reason}`, "error");
      pi.sendUserMessage(
        `The skill "${skill.name}" ran in a forked subagent but ${reason}.\n\nstderr:\n${result.stderr.trim() || "(empty)"}`,
      );
      return { action: "handled" };
    }

    pi.sendUserMessage(
      `Result of skill "${skill.name}" (ran in a forked subagent${modelRef ? ` on ${modelRef}` : ""}):\n\n${result.stdout.trim() || "(no output)"}`,
    );
    return { action: "handled" };
  });
}

function resolveClosestModel(
  requestedModel: unknown,
  ctx: { modelRegistry: Parameters<typeof resolveCliModel>[0]["modelRegistry"] },
): string | undefined {
  if (typeof requestedModel !== "string" || !requestedModel.trim()) return undefined;
  const resolved = resolveCliModel({
    cliModel: requestedModel.trim(),
    modelRegistry: ctx.modelRegistry,
  });
  if (!resolved.model) return undefined;
  return `${resolved.model.provider}/${resolved.model.id}`;
}

if (import.meta.main) {
  const assert = (cond: boolean, msg: string) => {
    if (!cond) throw new Error(`self-check failed: ${msg}`);
  };
  assert(parseSkillCommand("/skill:foo")?.name === "foo", "bare command");
  assert(parseSkillCommand("/skill:foo-2 do the thing")?.args === "do the thing", "args");
  assert(parseSkillCommand("  /skill:foo  ")?.name === "foo", "trims whitespace");
  assert(parseSkillCommand("/skill:Foo") === null, "rejects uppercase");
  assert(parseSkillCommand("hello /skill:foo") === null, "rejects mid-text");
  assert(parseSkillCommand("/skillz:foo") === null, "rejects wrong prefix");
  console.log("skill-context self-check OK");
}
