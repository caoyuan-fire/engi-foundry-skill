# Engineering Discipline

EngiFoundry includes built-in engineering discipline. Package ceremony may be light, but engineering quality must not be.

## TDD

For behavior changes, prefer test-first development.

If test-first development is not feasible, record why and provide alternative verification.

## Systematic Debugging

For bugs and failures:

1. Reproduce or characterize the symptom.
2. Gather evidence.
3. Form a hypothesis.
4. Make a targeted fix.
5. Verify the result.

Do not jump from symptom to broad rewrite without evidence.

## Review

Review should check:

- scope;
- correctness;
- requirement linkage;
- implementation equivalence;
- tests;
- verification evidence;
- record consistency;
- risks.

Review findings should be ordered by severity and tied to evidence.

## Verification Before Completion

No completion claim is allowed without fresh verification evidence or an explicit non-runnable verification record.

Failed verification is a failed result.

If verification cannot be run, record:

- why it cannot be run;
- what alternative evidence was collected;
- what residual risk remains.
