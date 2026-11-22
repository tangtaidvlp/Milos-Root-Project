# Feature Specification: Spec Kit Practice Run

**Feature Branch**: `F003-skill-test-no-functional-implementation`

**Created**: 2026-11-21

**Status**: Draft

**Input**: Feature request ticket `specs/F003-skill-test-no-functional-implementation/F003-skill-test-no-functional-implementation.md` ("Test claude working with speckit")

## User Scenarios & Testing *(mandatory)*

This feature changes nothing in the Personal Routine Manager app. It is a practice run of the Spec Kit cycle on a safe ticket. Its outputs are documents for the workspace owner (the only user), plus improvements to the Spec Kit setup itself.

### User Story 1 - Follow a standard Spec Kit workflow (Priority: P1)

The owner wants one written, repeatable way of taking a feature from idea to code with Spec Kit in this workspace. The guide covers each step in order: what the step is for, what it reads and writes, when to run it, and how to go back to an earlier step when something changes.

**Why this priority**: A standard workflow is the main reason for the ticket. The quiz and the improvements both build on it.

**Independent Test**: The owner starts a new dummy feature using only the guide, without asking Claude how to proceed, and reaches a generated task list.

**Acceptance Scenarios**:

1. **Given** the guide, **When** the owner wants to start a new feature, **Then** the guide names the first command to run and where to write the feature description.
2. **Given** a spec that already has a plan and tasks, **When** the owner changes a requirement, **Then** the guide says which steps to re-run, in what order, and how to check that the documents still agree.
3. **Given** the guide, **When** the owner meets a bug instead of a feature, **Then** the guide points to the separate bug workflow.
4. **Given** the guide, **When** the owner reads it, **Then** it explains in plain words what spec-driven development (SDD) is and why the spec comes before the code.

---

### User Story 2 - Check understanding with a quiz (Priority: P2)

The owner wants a set of questions about the Spec Kit workflow and SDD, with an answer key, to check what they have understood.

**Why this priority**: This is the ticket's stated way of knowing the feature works ("You can provide me some questions").

**Independent Test**: The owner answers the questions without looking at the answer key, then marks their answers against it.

**Acceptance Scenarios**:

1. **Given** the quiz, **When** the owner reads a question, **Then** they can answer it from the guide and from running the workflow; it does not depend on Spec Kit internals the guide never covers.
2. **Given** an answer, **When** the owner checks the answer key, **Then** the key gives the correct answer and a one-line reason or a pointer to the guide section.
3. **Given** the quiz, **When** the owner looks at it as a whole, **Then** it covers every workflow step, going back to an earlier step, where files are kept, and the ideas behind SDD.

---

### User Story 3 - Improve the Spec Kit setup from what the practice run shows (Priority: P3)

While the cycle runs on this ticket, friction is noted, such as confusing steps, missing instructions, or wrong file references. Each item is fixed in the workspace's Spec Kit skills or templates.

**Why this priority**: The owner wants to improve their Spec Kit work. Fixes are worth most after the workflow is written down and tried.

**Independent Test**: Each improvement is listed with the problem it solves, and re-running the affected step shows the problem is gone.

**Acceptance Scenarios**:

1. **Given** friction met during the practice run, **When** it is recorded, **Then** the record names the step, what went wrong, and the change made.
2. **Given** an improvement to a skill or template, **When** the affected step is run again, **Then** the friction no longer happens.
3. **Given** an improvement that touches a file Spec Kit upgrades can overwrite, **When** it is recorded, **Then** the record says so.

---

### User Story 4 - Prepare criteria for a later comparison (Priority: P4)

The owner plans to compare Spec Kit with Matt Pocock's approach later. This feature produces the list of points to compare on, so the later comparison is consistent. It does not do the comparison itself.

**Why this priority**: The owner asked for it now, but the comparison itself is later work.

**Independent Test**: The owner reads the criteria list and can say, for each point, how they would measure it for Spec Kit using this practice run.

**Acceptance Scenarios**:

1. **Given** the criteria list, **When** the owner reads a criterion, **Then** it says what is being compared and how to observe or measure it.
2. **Given** the criteria list, **When** the owner reviews it, **Then** each criterion has a Spec Kit observation from this practice run, and the Matt Pocock column is left empty for later.

---

### Edge Cases

- What if the practice run finds friction that cannot be fixed in a skill or template, for example a limit of Spec Kit itself? It is recorded as a known limitation in the guide, not fixed.
- What if an improvement changes a step the guide already describes? The guide is updated so it matches the improved step.
- What if a quiz question turns out to have more than one defensible answer? The question is reworded or removed.
- What if a later step, such as plan or tasks, finds nothing to build because there is no app code? The step still runs and its output records that the deliverables are documents and setup changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST produce a workflow guide covering, in order: creating a feature draft, generating the spec, clarifying, planning, generating tasks, checking consistency, implementing, and checking what is still unbuilt.
- **FR-002**: For each step, the guide MUST state its purpose, what it reads, what it writes, and when to run it.
- **FR-003**: The guide MUST explain how to go back to an earlier step when something upstream changes, and which later steps must then be re-run.
- **FR-004**: The guide MUST explain how the owner and Claude discuss a feature through the draft ticket, including the `Waiting on user` status and resuming.
- **FR-005**: The guide MUST point to the separate bug workflow and say when to use it instead.
- **FR-006**: The guide MUST include a short plain-language explanation of spec-driven development.
- **FR-007**: The feature MUST produce a quiz of at least 10 questions with an answer key, covering every step in FR-001, going back to an earlier step, where files live, and SDD ideas.
- **FR-008**: Each answer in the key MUST include a short reason or a reference to the guide section that supports it.
- **FR-009**: Friction found during the practice run MUST be recorded with: the step, the problem, and the change made (or "not fixable" with a reason).
- **FR-010**: Improvements to Spec Kit skills and templates MAY be made as part of this feature. Each MUST be recorded per FR-009 and MUST say whether a Spec Kit upgrade could overwrite it.
- **FR-011**: The feature MUST produce a list of comparison criteria. Each criterion MUST say what is compared and how to observe it, and MUST include the Spec Kit observation from this practice run.
- **FR-012**: The feature MUST NOT change any file in the backend or frontend app projects.

### Key Entities

- **Workflow guide**: The owner's standard Spec Kit workflow for this workspace. It is organized by step and kept in line with the actual skills.
- **Quiz**: Questions with an answer key, each answer linked to a guide section.
- **Improvement log**: One entry per friction item: step, problem, change, whether an upgrade could overwrite it.
- **Comparison criteria**: Points to compare spec-driven approaches on, each with a way to measure it and the Spec Kit observation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Using only the guide, the owner takes a new dummy feature from draft to task list without asking for help.
- **SC-002**: The owner answers at least 80% of the quiz correctly on the first try without the answer key.
- **SC-003**: Every friction item recorded during the practice run is either fixed (re-running the step confirms it) or marked "not fixable" with a reason. None are left open.
- **SC-004**: At least 6 comparison criteria exist, each with a Spec Kit observation filled in.
- **SC-005**: Zero files change in the backend and frontend app projects.

## Assumptions

- The only user is the workspace owner, working alone.
- The guide, quiz, improvement log and comparison criteria live inside this feature's folder, `specs/F003-skill-test-no-functional-implementation/`. The plan may choose the file layout.
- "No project code change" covers the backend and frontend app projects only. The owner explicitly allowed Spec Kit skill and template changes (see the ticket's Discussion log).
- The guide describes the Spec Kit setup as it exists in this workspace, including local changes such as `/speckit-feature-init` and the draft ticket flow, not only upstream Spec Kit.
- The comparison with Matt Pocock's approach itself is out of scope. Only the criteria are prepared now.
