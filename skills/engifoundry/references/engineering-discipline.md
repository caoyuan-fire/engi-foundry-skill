# Engineering Discipline

EngiFoundry includes four mandatory engineering disciplines.

## TDD

For behavior changes, prefer test-first. If not feasible, record why and provide alternative verification.

## Systematic Debugging

For bugs and failures:

1. Reproduce or characterize the symptom.
2. Gather evidence.
3. Form a hypothesis.
4. Make a targeted fix.
5. Verify the result.

Do not jump from symptom to broad rewrite without evidence.

## Review

Review:

- scope;
- correctness;
- requirement linkage;
- implementation equivalence;
- tests;
- verification evidence;
- record consistency;
- risks.

Review findings should be ordered by severity and tied to evidence.

Follow-up reviews after rework are not delta-only. The final review decision must consider the complete current Job state, including scope, acceptance criteria, verification evidence, record consistency, and remaining risk.

## Bounded Rework Gate

Bounded Rework Gate only applies after work enters a package flow.

Packages or Jobs may declare an explicit `reworkLimit`.

If no explicit limit exists and the same class of rework fails more than twice, return to `primary/control` for failure alignment before continuing. Failure alignment should decide whether to revise scope, revise the Job contract, change executor strategy, add evidence, block the Job, or stop the package.

Rework must preserve the package-first conflict rule. Executor or reviewer sessions must not use rework as a reason to expand scope, edit forbidden areas, skip verification, or approve their own completion.

## Verification Before Completion

Do not claim completion without fresh verification evidence or an explicit non-runnable verification record.

Failed verification is a failed result.

If verification cannot be run, record why, what alternative evidence was collected, and what residual risk remains.
