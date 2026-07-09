# Project Workflow

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **Test-Driven Development:** Write unit tests before implementing functionality
4. **High Code Coverage:** Aim for >90% code coverage for all modules. Zero tolerance for untested business logic.
5. **User Experience First:** Every decision should prioritize user experience
6. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.
7. **Strict Security & Linting:** Run RuboCop and Brakeman on every task completion. No offences/warnings are allowed.
8. **No Accepted Known Risk:** No known security, privacy, accessibility, data-integrity, availability, correctness, or quality risk may be accepted as "low risk" and carried forward. Every identified risk must be eliminated, mitigated with a verified control, converted into a blocking task, or explicitly deferred only behind a disabled-by-default feature flag plus a dated Conductor follow-up.
9. **Harness Engineering First:** Treat the repo as an agent- and human-operable harness. Every meaningful change must improve or preserve feedforward guides and feedback sensors: specifications, plans, style guides, architecture rules, tests, linters, type checks, security scanners, benchmark scripts, observability, and runbooks. Prefer deterministic computational controls for every-change enforcement, with inferential review used as an additional sensor rather than a substitute.
10. **Keep Quality Left:** Put fast, deterministic checks as early as possible in local development, task verification, and CI. Expensive sensors such as mutation testing, broad architecture review, profiling, and full E2E suites still need defined execution points and cannot be skipped silently.

## Task Workflow

All tasks follow a strict lifecycle:

### Issue-Led Delivery

1. **Parent Issue for Strategic Work:** Each strategic improvement area must have a GitHub parent issue that describes the outcome, risk posture, harness model, rollout constraints, and links back to the relevant Conductor track.
2. **Subissues for Reviewable Units:** Parent issues must be decomposed into small subissues that can be implemented, reviewed, and reverted independently. A subissue should normally map to one focused PR.
3. **Small PR Standard:** Each PR must address one narrow aspect of one subissue. If a reviewer cannot understand the intent, risk, tests, rollback path, and harness impact quickly, the PR is too large.
4. **PRs Attach to Issues:** Every implementation PR must link a subissue, name the parent issue or Conductor track, and include verification evidence. Work without a linked issue is limited to emergency fixes or trivial documentation corrections.
5. **No Risk Carry-Forward:** A subissue cannot be closed while it has unresolved known security, privacy, accessibility, data-integrity, availability, correctness, quality, or operator risk. Low severity still counts as unresolved risk unless fixed, verified false positive, mitigated, or converted into a blocking follow-up.
6. **Harness Evidence:** Every issue and PR should identify the relevant feedforward guide and feedback sensor. If no sensor exists, the first PR should add or document one before changing production behavior.
7. **Progressive Rollout:** Prefer documentation, advisory checks, benchmarks, profiling, and feature-flagged pilots before mandatory enforcement or user-visible behavior changes.

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order

2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`

3. **Write Failing Tests (Red Phase):**
   - Create a new test file for the feature or bug fix.
   - Write one or more unit tests that clearly define the expected behavior and acceptance criteria for the task.
   - **CRITICAL:** Run the tests and confirm that they fail as expected. This is the "Red" phase of TDD. Do not proceed until you have failing tests.

4. **Implement to Pass Tests (Green Phase):**
   - Write the minimum amount of application code necessary to make the failing tests pass.
   - Run the test suite again and confirm that all tests now pass. This is the "Green" phase.

5. **Refactor (Optional but Recommended):**
   - With the safety of passing tests, refactor the implementation code and the test code to improve clarity, remove duplication, and enhance performance without changing the external behavior.
   - Rerun tests to ensure they still pass after refactoring.

6. **Verify Coverage:** Run coverage reports using the project's chosen tools.
   Target: >90% coverage for new code. The specific tools and commands will vary by language and framework.

7. **Run Static Checks:** Run RuboCop and Brakeman to verify code quality and security.
   ```bash
   bundle exec rubocop
   bundle exec brakeman
   ```
   All checks must pass with zero offenses/warnings.

8. **Run Risk and Harness Review:**
   - Identify any security, privacy, accessibility, data-integrity, availability, correctness, performance, maintainability, or operator-risk introduced or exposed by the task.
   - Confirm every identified risk has a passing deterministic sensor where practical, such as a regression test, lint rule, type check, scanner, contract, benchmark threshold, or runbook verification.
   - If any known risk remains without a verified mitigation, **STOP** and add or update a blocking Conductor task before proceeding.
   - Update feedforward guides or feedback sensors when the task reveals a repeated failure mode, missing rule, or missing verification surface.

9. **Document Deviations:** If implementation differs from tech stack:
   - **STOP** implementation
   - Update `tech-stack.md` with new design
   - Add dated note explaining the change
   - Resume implementation

10. **Commit Code Changes:**
   - Stage all code changes related to the task.
   - Propose a clear, concise commit message e.g, `feat(ui): Create basic HTML structure for calculator`.
   - Perform the commit.

11. **Attach Task Summary with Git Notes:**
   - **Step 9.1: Get Commit Hash:** Obtain the hash of the *just-completed commit* (`git log -1 --format="%H"`).
   - **Step 9.2: Draft Note Content:** Create a detailed summary for the completed task. This should include the task name, a summary of changes, a list of all created/modified files, and the core "why" for the change.
   - **Step 9.3: Attach Note:** Use the `git notes` command to attach the summary to the commit.
     ```bash
     # The note content from the previous step is passed via the -m flag.
     git notes add -m "<note content>" <commit_hash>
     ```

12. **Get and Record Task Commit SHA:**
    - **Step 10.1: Update Plan:** Read `plan.md`, find the line for the completed task, update its status from `[~]` to `[x]`, and append the first 7 characters of the *just-completed commit's* commit hash.
    - **Step 10.2: Write Plan:** Write the updated content back to `plan.md`.

13. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message (e.g., `conductor(plan): Mark task 'Create user model' as complete`).

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** This protocol is executed immediately after a task is completed that also concludes a phase in `plan.md`.

1.  **Announce Protocol Start:** Inform the user that the phase is complete and the verification and checkpointing protocol has begun.

2.  **Ensure Test Coverage for Phase Changes:**
    -   **Step 2.1: Determine Phase Scope:** To identify the files changed in this phase, you must first find the starting point. Read `plan.md` to find the Git commit SHA of the *previous* phase's checkpoint. If no previous checkpoint exists, the scope is all changes since the first commit.
    -   **Step 2.2: List Changed Files:** Execute `git diff --name-only <previous_checkpoint_sha> HEAD` to get a precise list of all files modified during this phase.
    -   **Step 2.3: Verify and Create Tests:** For each file in the list:
        -   **CRITICAL:** First, check its extension. Exclude non-code files (e.g., `.json`, `.md`, `.yaml`).
        -   For each remaining code file, verify a corresponding test file exists.
        -   If a test file is missing, you **must** create one. Before writing the test, **first, analyze other test files in the repository to determine the correct naming convention and testing style.** The new tests **must** validate the functionality described in this phase's tasks (`plan.md`).

3.  **Execute Automated Tests with Proactive Debugging:**
    -   Before execution, you **must** announce the exact shell command you will use to run the tests.
    -   **Example Announcement:** "I will now run the automated test suite to verify the phase. **Command:** `CI=true npm test`"
    -   Execute the announced command.
    -   If tests fail, you **must** inform the user and begin debugging. You may attempt to propose a fix a **maximum of two times**. If the tests still fail after your second proposed fix, you **must stop**, report the persistent failure, and ask the user for guidance.

4.  **Propose a Detailed, Actionable Manual Verification Plan:**
    -   **CRITICAL:** To generate the plan, first analyze `product.md`, `product-guidelines.md`, and `plan.md` to determine the user-facing goals of the completed phase.
    -   You **must** generate a step-by-step plan that walks the user through the verification process, including any necessary commands and specific, expected outcomes.
    -   The plan you present to the user **must** follow this format:

        **For a Frontend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Start the development server with the command:** `npm run dev`
        2.  **Open your browser to:** `http://localhost:3000`
        3.  **Confirm that you see:** The new user profile page, with the user's name and email displayed correctly.
        ```

        **For a Backend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Ensure the server is running.**
        2.  **Execute the following command in your terminal:** `curl -X POST http://localhost:8080/api/v1/users -d '{"name": "test"}'`
        3.  **Confirm that you receive:** A JSON response with a status of `201 Created`.
        ```

5.  **Await Explicit User Feedback:**
    -   After presenting the detailed plan, ask the user for confirmation: "**Does this meet your expectations? Please confirm with yes or provide feedback on what needs to be changed.**"
    -   **PAUSE** and await the user's response. Do not proceed without an explicit yes or confirmation.

6.  **Create Checkpoint Commit:**
    -   Stage all changes. If no changes occurred in this step, proceed with an empty commit.
    -   Perform the commit with a clear and concise message (e.g., `conductor(checkpoint): Checkpoint end of Phase X`).

7.  **Attach Auditable Verification Report using Git Notes:**
    -   **Step 7.1: Draft Note Content:** Create a detailed verification report including the automated test command, the manual verification steps, and the user's confirmation.
    -   **Step 7.2: Attach Note:** Use the `git notes` command and the full commit hash from the previous step to attach the full report to the checkpoint commit.

8.  **Get and Record Phase Checkpoint SHA:**
    -   **Step 8.1: Get Commit Hash:** Obtain the hash of the *just-created checkpoint commit* (`git log -1 --format="%H"`).
    -   **Step 8.2: Update Plan:** Read `plan.md`, find the heading for the completed phase, and append the first 7 characters of the commit hash in the format `[checkpoint: <sha>]`.
    -   **Step 8.3: Write Plan:** Write the updated content back to `plan.md`.

9. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message following the format `conductor(plan): Mark phase '<PHASE NAME>' as complete`.

10.  **Announce Completion:** Inform the user that the phase is complete and the checkpoint has been created, with the detailed verification report attached as a git note.

### Quality Gates

Before marking any task complete, verify:

- [ ] All tests pass
- [ ] Code coverage meets requirements (>90%)
- [ ] Code follows project's code style guidelines (as defined in `code_styleguides/`)
- [ ] RuboCop reports zero style offenses
- [ ] Brakeman reports zero security vulnerabilities
- [ ] All dependency and modern security scanners configured for the task report zero untriaged findings
- [ ] All public functions/methods are documented (e.g., docstrings, JSDoc, GoDoc)
- [ ] Type safety is enforced (e.g., type hints, TypeScript types, Go types)
- [ ] No linting or static analysis errors (using the project's configured tools)
- [ ] Works correctly on mobile (if applicable)
- [ ] Documentation updated if needed
- [ ] No security vulnerabilities introduced
- [ ] No known quality, security, privacy, accessibility, data-integrity, availability, correctness, or operational risk remains unmitigated
- [ ] Feedforward guides and feedback sensors were updated when the task exposed a missing rule, missing test, missing scanner, or repeated failure mode

## Development Commands

**AI AGENT INSTRUCTION: This section should be adapted to the project's specific language, framework, and build tools.**

### Setup
```bash
# Example: Commands to set up the development environment (e.g., install dependencies, configure database)
# e.g., for a Node.js project: npm install
# e.g., for a Go project: go mod tidy
```

### Daily Development
```bash
# Example: Commands for common daily tasks (e.g., start dev server, run tests, lint, format)
# e.g., for a Node.js project: npm run dev, npm test, npm run lint
# e.g., for a Go project: go run main.go, go test ./..., go fmt ./...
```

### Before Committing
```bash
# Run the test suite and static code quality/security analysis
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## Testing Requirements

### Unit Testing
- Every module must have corresponding tests.
- Use appropriate test setup/teardown mechanisms (e.g., fixtures, beforeEach/afterEach).
- Mock external dependencies.
- Test both success and failure cases.

### Integration Testing
- Test complete user flows
- Verify database transactions
- Test authentication and authorization
- Check form submissions

### Mobile Testing
- Test on actual iPhone when possible
- Use Safari developer tools
- Test touch interactions
- Verify responsive layouts
- Check performance on 3G/4G

## Code Review Process

### Self-Review Checklist
Before requesting review:

1. **Functionality**
   - Feature works as specified
   - Edge cases handled
   - Error messages are user-friendly

2. **Code Quality**
   - Follows style guide
   - DRY principle applied
   - Clear variable/function names
   - Appropriate comments

3. **Testing**
   - Unit tests comprehensive
   - Integration tests pass
   - Coverage adequate (>80%)

4. **Security**
   - No hardcoded secrets
   - Input validation present
   - SQL injection prevented
   - XSS protection in place
   - No known security finding is accepted as low risk without a verified mitigation and Conductor follow-up

5. **Performance**
   - Database queries optimized
   - Images optimized
   - Caching implemented where needed

6. **Mobile Experience**
   - Touch targets adequate (44x44px)
   - Text readable without zooming
   - Performance acceptable on mobile
   - Interactions feel native

7. **Harness Quality**
   - The change has clear feedforward guidance in specs, plans, style guides, or runbooks
   - The change has feedback sensors in tests, linters, type checks, scanners, benchmarks, logs, or CI
   - Fast deterministic sensors run locally or in pre-merge CI; expensive sensors have documented scheduled or release-gate execution

## Commit Guidelines

### Message Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests
- `chore`: Maintenance tasks

### Examples
```bash
git commit -m "feat(auth): Add remember me functionality"
git commit -m "fix(posts): Correct excerpt generation for short posts"
git commit -m "test(comments): Add tests for emoji reaction limits"
git commit -m "style(mobile): Improve button touch targets"
```

## Definition of Done

A task is complete when:

1. All code implemented to specification
2. Unit tests written and passing
3. Code coverage meets project requirements
4. Documentation complete (if applicable)
5. Code passes all configured linting and static analysis checks
6. Works beautifully on mobile (if applicable)
7. No known security, privacy, accessibility, data-integrity, availability, correctness, quality, or operational risk remains unmitigated
8. Required harness guides and sensors are present and documented
9. Implementation notes added to `plan.md`
10. Changes committed with proper message
11. Git note with task summary attached to the commit

## 1,000-Point PR Health Audit

To achieve the highest standards of production-readiness, security, and SRE resilience, every completed track must undergo a comprehensive 1,000-point PR Health Audit. The audit targets a minimum passing score of **995 / 1,000** and evaluates 10 key technical dimensions (each worth 100 points):

1. **Throttling & Limit Policies (100 pts):** Correct initialization of verified bot tiers, anonymous IP ceilings, and rate limit rules.
2. **Fail2Ban Security Controls (100 pts):** Auto-banning triggers, ban windows, and downstream subscriber tracking.
3. **High-Availability Redis Circuit-Breakers (100 pts):** Connection failure handling, resilient caching wrapper, and graceful fail-open logic.
4. **Dynamic Load-Based Rate Limits (100 pts):** Active Sidekiq/server load checks and dynamic anonymous rate reductions during traffic spikes.
5. **Traffic Control Headers (100 pts):** Auto-injection of standard RFC back-pressure headers (`RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`) with O(1) request env lookups.
6. **HTTP Caching & ETag Coordination (100 pts):** Server-side `ETag`/`Last-Modified` headers, 304 response checks, and client-side database ETag cache tables to minimize database reads and page rendering.
7. **JSON Streaming & Bulk Export APIs (100 pts):** NDJSON-formatted export streaming in batches (flat memory usage) with authenticated bot token verification.
8. **Sidekiq Queue Prioritization (100 pts):** Global request attributes carried over thread boundaries, routing expensive bot tasks to `bulk_processor` queues.
9. **Docker & Orchestration Updates (100 pts):** Compose service healthchecks, startup constraints, and local load/attack simulation test suites.
10. **Test Coverage & Conventional Commit Standards (100 pts):** comprehensive unit/integration test suites in both Ruby/Python, Conventional Commits messages, and `git notes` summaries.

Every PR must document its audit score and explanation in the PR description and Conductor final report.

## Emergency Procedures

### Critical Bug in Production
1. Create hotfix branch from main
2. Write failing test for bug
3. Implement minimal fix
4. Test thoroughly including mobile
5. Deploy immediately
6. Document in plan.md

### Data Loss
1. Stop all write operations
2. Restore from latest backup
3. Verify data integrity
4. Document incident
5. Update backup procedures

### Security Breach
1. Rotate all secrets immediately
2. Review access logs
3. Patch vulnerability
4. Notify affected users (if any)
5. Document and update security procedures

## Deployment Workflow

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Coverage >90%
- [ ] No linting or security scanner (RuboCop, Brakeman) errors
- [ ] No known unresolved risk remains, including findings classified by scanners as low severity
- [ ] Harness sensors for the deployment path have run or have an explicit blocking reason recorded in Conductor
- [ ] Mobile testing complete
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Backup created

### Deployment Steps
1. Merge feature branch to main
2. Tag release with version
3. Push to deployment service
4. Run database migrations
5. Verify deployment
6. Test critical paths
7. Monitor for errors

### Post-Deployment
1. Monitor analytics
2. Check error logs
3. Gather user feedback
4. Plan next iteration

## Continuous Improvement

- Review workflow weekly
- Update based on pain points
- Document lessons learned
- Optimize for user happiness
- Keep things simple and maintainable
- When a defect, risk, review comment, or agent failure mode repeats, improve at least one feedforward guide and one feedback sensor so the repo becomes easier to govern next time
- Review harness coverage regularly across maintainability, architecture fitness, and behaviour: deterministic checks first, inferential review where semantic judgment is required
