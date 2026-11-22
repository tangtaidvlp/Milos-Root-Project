# Bugfix: [BUG TITLE]

**Bugfix Branch**: `[###-fix-short-name]`
**Created**: [DATE]
**Status**: Investigating | Root cause confirmed | Fixed | Escalated
**Affected project(s)**: [ms-personal-routine-manager | ui-personal-routine-manager | both]
**Input**: Bug report: "$ARGUMENTS"

## 1. Report

**Expected behavior**: [What should happen]

**Actual behavior**: [What happens instead, with exact error text, status code, or stack trace excerpt]

**Environment**: [Spring profile (local/fast/sit/...), browser, endpoint, data conditions]

**Severity**: [Critical: data loss, security, outage | High: core flow broken | Medium: workaround exists | Low: cosmetic]

## 2. Reproduction

**Steps**:

1. [Step]
2. [Step]

**Reproduced?**: [Yes, every time | Yes, intermittently (N of M runs) | No, see notes]

**Smallest reproduction**: [The narrowest command, request, or test that shows the bug]

## 3. Investigation

| # | Hypothesis | How it was tested | Result |
|---|------------|-------------------|--------|
| H1 | [Suspected cause] | [Log, breakpoint, query, experiment] | [Confirmed / Ruled out: evidence] |

## 4. Root Cause

**Location**: [path/to/File.java:123]

**Cause**: [Why the defect happens: the faulty assumption or logic, not the symptom]

**Introduced by**: [Commit, feature spec, or "unknown"]

**Blast radius**: [Other callers, endpoints, or UI views that share the faulty code path]

## 5. Regression Test

**Test**: [path/to/Test.java#methodName, or the manual check if no test framework applies]

**Failed before fix**: [Yes: failure output excerpt]

## 6. Fix

**Change summary**: [What changed and why this addresses the root cause]

**Files changed**:

- [path/to/file]: [what changed]

**Alternatives rejected**: [Other fixes considered and why they were not chosen]

## 7. Verification

- [ ] Regression test passes
- [ ] Full test suite for the affected project passes (or failures shown to be unrelated)
- [ ] Lint/build passes for the affected project
- [ ] Original reproduction steps no longer show the bug
- [ ] API contract still aligned between backend and frontend (if a request/response shape changed)

**Follow-ups**: [Related issues found but left out of scope]
