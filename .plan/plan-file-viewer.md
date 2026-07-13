# Plan-file viewer — generate-and-open (option C)

**Status:** in-progress
**Goal:** A `plan-view [slug]` command that reads a plan from `$PWD/.plan/` (single file or the
folder shape), inlines every file into one self-contained HTML document, writes it to a temp file,
and `open`s it via `file://`. Because all plan content is embedded, the folder shape gets a sidebar
that navigates between phase files client-side — **no server, no CORS, no process left running**.
Re-run to refresh after edits.

## Context

- Plan format: `~/.claude/skills/plan/SKILL.md` — single `.plan/<slug>.md`, or folder
  `.plan/<slug>/index.md` + `01-tooling.md`… Phase links read `see 01-tooling.md`. `.plan/` is a
  working dir (uncommitted), so a generated `.html` doesn't belong in git — write it to `tempfile`.
- Script exposure: repo wires CLIs as flake packages (`pkgs/`, `flake.nix:106`), but those are all
  upstream sources. A one-file personal script is lazier as a zsh alias → flakePath, edit-and-go
  (matches `zdot`/`zshrc` aliases at `home-manager/shell/zsh.nix:31`, which already use
  `${osConfig.flakePath}`). `python3` is on PATH (mise); `open` is macOS (pelico is the only host).
- No `fetch()`/`file://` problem here: content is inlined as JSON, not fetched. Markdown → HTML is
  done in-browser by `marked` via a CDN `<script>` (loads fine over `file://`).
  <!-- ponytail: CDN marked; vendor marked.min.js into the template if offline viewing is needed -->

## Steps

- [ ] Write `home-manager/applications/claude-code/plan-view.py` (generator):
  - Arg: optional `slug`. Resolve against `Path.cwd()/".plan"`. If omitted and exactly one plan
    exists, use it; else print the available slugs and exit.
  - Collect files: `.plan/<slug>.md` → `[that file]`; `.plan/<slug>/` → `index.md` first, then the
    rest sorted by the numeric `NN-` prefix (natural order), then alpha. Read each as UTF-8 into an
    ordered `{name: markdown}` dict; error clearly if the slug resolves to neither.
  - Build HTML from a template string: `<script src="https://cdn.jsdelivr.net/npm/marked@15/marked.min.js">`,
    inline `<style>` (readable column, sidebar, code blocks, GFM task-list checkboxes), and
    `const FILES = {json};` (`json.dumps` of the dict). Inline JS: build sidebar from `FILES` keys
    (hidden if only one), `render(name)` = `marked.parse(FILES[name], {gfm:true})` into `#content`
    - highlight active entry, render `index.md`/lone file on load, and intercept clicks on
      `<a href="NN-*.md">` that exist in `FILES` → `render()` that file instead of navigating.
  - Write to `tempfile.NamedTemporaryFile(suffix=".html", delete=False)` and
    `subprocess.run(["open", path])`. Print the temp path.
  - Leave one runnable self-check: `python3 plan-view.py --selftest` builds HTML from a fixture
    dict and asserts the file names + `FILES` JSON are present in the output (no browser).
- [ ] Add alias in `home-manager/shell/zsh.nix:31`:
      `plan-view = "python3 ${osConfig.flakePath}/home-manager/applications/claude-code/plan-view.py"`.
- [ ] `git add -A` (flakes ignore untracked) && `nix run .#apply`; open a new shell.
- [ ] Verify acceptance below against this repo's `.plan/` and a folder-shaped fixture.

## Acceptance

- `plan-view plan-file-viewer` (single file) → browser opens the rendered plan; `- [ ]`/`- [x]`
  show as checkboxes; no sidebar (or a single entry).
- On a folder plan → sidebar lists `index.md` first then phases in numeric order; clicking an entry
  swaps the pane; a `see 01-tooling.md` link jumps to that file without page navigation.
- Editing a `.md` then re-running `plan-view <slug>` reflects the change (regenerates).
- `plan-view` with no arg and one plan opens it; with several, lists slugs.
- No server process is started; closing the tab leaves nothing running (temp file is the only trace).
- `python3 plan-view.py --selftest` passes.

## Out of scope (skipped, add when)

- Toggling checkboxes back to the `.md` — needs write access from the browser (File System Access
  API / a server). Add when you want to tick boxes from the viewer.
- Offline: vendoring `marked.min.js` into the template — add when you read plans without network.
- Live reload on `.md` change — it's a static snapshot; re-run to refresh. Add a watcher only if
  regenerating by hand gets annoying.
- Packaging as a flake `pkgs/` derivation / other hosts — alias-to-script covers pelico. Add when a
  second host needs it.

## Log

- 2026-07-13 Picked option C (generate self-contained HTML per plan, then `open`). Folder nav comes
  free by embedding all phase files as JSON and switching panes client-side. Chosen over glow, a
  shared server, and a picker-based static viewer.
