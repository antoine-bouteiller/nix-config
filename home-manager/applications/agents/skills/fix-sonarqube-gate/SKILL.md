---
name: fix-sonarqube-gate
allowed-tools: Bash(sonar:*), Bash(git:*)
description: Diagnose and fix a failing SonarQube quality gate on the current branch's merge request — resolves the project + PR, reads the failing conditions, then fixes new violations and coverage gaps. Use when the user says "fix the sonarqube gate", "the sonar quality gate is failing", or after a pipeline reports a red SonarQube check.
---

# Fix the SonarQube quality gate

Find why the gate is red on the current branch and fix it. The gate is evaluated
per **merge request**, not per local branch — so you resolve the PR key first,
read its failing conditions, then fix them at the source (code + tests).

Use the `sonar` CLI (`sonar api ...`) directly. It reads its token from the OS
keychain and needs nothing else. Confirm auth once with `sonar auth status`.

## 1. Resolve the project key

The key is not in `sonar-project.properties` (it's set via CI env vars). List
projects and match the repo:

```bash
sonar list projects | python3 -c "import sys,json;[print(p['key'],p['name']) for p in json.load(sys.stdin)['projects']]" | grep -i <repo-name>
```

e.g. the Phoenix repo → `data-platform-phoenix`.

## 2. Find the failing PR for this branch

```bash
git branch --show-current
sonar api get "/api/project_pull_requests/list?project=<key>" | python3 -c "
import sys,json
for p in json.load(sys.stdin).get('pullRequests',[]):
    print(p['key'], p['branch'], p['status'].get('qualityGateStatus'))
" | grep <branch>
```

Grab the numeric PR `key`. If there's no PR yet, fall back to the analyzed main
branch (`main`/`master`, not the local feature branch):
`/api/qualitygates/project_status?projectKey=<key>&branch=<main-branch>`.

## 3. Read the failing conditions

```bash
sonar api get "/api/qualitygates/project_status?projectKey=<key>&pullRequest=<pr>" \
  | python3 -m json.tool
```

Each condition has `metricKey`, `status`, `errorThreshold`, `actualValue`. Only
fix the ones with `status: ERROR`. The common two:

### `new_violations` (threshold 0)

List them, then fix each at its source — do **not** rely on `sonar.issue.ignore`
unless it's a genuine project-wide convention already established in
`sonar-project.properties`.

```bash
sonar api get "/api/issues/search?componentKeys=<key>&pullRequest=<pr>&resolved=false&inNewCodePeriod=true&ps=500" \
  | python3 -c "
import sys,json
for i in json.load(sys.stdin).get('issues',[]):
    print(i['rule'],'|',i.get('severity'),'|',i['component'].split(':')[-1],':',i.get('line'))
    print('   ',i.get('message'))
"
```

If the response `paging.total` exceeds 500, page through with `&p=<n>` — don't
declare violations fixed off a truncated first page.

### `new_coverage` (threshold usually 80%)

Get the totals and the worst files, then add real unit tests for the biggest,
most-testable gaps (pure functions first — highest coverage per line of test):

```bash
sonar api get "/api/measures/component?component=<key>&pullRequest=<pr>&metricKeys=new_coverage,new_lines_to_cover,new_conditions_to_cover,new_uncovered_lines,new_uncovered_conditions" \
  | python3 -m json.tool

sonar api get "/api/measures/component_tree?component=<key>&pullRequest=<pr>&metricKeys=new_uncovered_lines,new_uncovered_conditions,new_lines_to_cover&qualifiers=FIL&s=metric&metricSort=new_uncovered_lines&asc=false&ps=20" \
  | python3 -c "
import sys,json
for c in json.load(sys.stdin).get('components',[]):
    m={x['metric']:x.get('period',{}).get('value',x.get('value')) for x in c.get('measures',[])}
    unc=int(m.get('new_uncovered_lines') or 0)+int(m.get('new_uncovered_conditions') or 0)
    if unc:
        print(unc,'uncovered /',m.get('new_lines_to_cover'),c['path'])
"
```

**Coverage math** — SonarQube counts lines _and_ branch conditions. With
`to_cover = new_lines_to_cover + new_conditions_to_cover` and
`uncovered = new_uncovered_lines + new_uncovered_conditions`, coverage is
`(to_cover − uncovered) / to_cover`. To reach 80%, drop `uncovered` to
`≤ 0.2 × to_cover`. Cover whole files so the count stays easy to reason about;
overshoot slightly — CI recomputes on push.

## 4. Fix, then verify locally

- **Violations**: fix the code (refactor, not suppress). Re-lint/typecheck the file.
- **Coverage**: write tests next to the code, matching the module's existing test
  style (framework, naming, given/when/then). Run them; confirm green.
- Match repo conventions from `CLAUDE.md` / `.claude/rules/`.

The gate only re-evaluates when CI re-runs analysis on the pushed commit — local
green is necessary but not sufficient. Tell the user the fixes are in and the gate
rechecks on push.
