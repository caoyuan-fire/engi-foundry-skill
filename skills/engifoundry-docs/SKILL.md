---
name: engifoundry-docs
description: Create a detailed human-readable document from EngiFoundry project records when the user explicitly requests documentation, a report, guide, specification, detailed summary, or handoff document.
---

# EngiFoundry Docs

## Scope

Use this supporting Skill only for an explicit request for a detailed document. Routine pause records and required PAK delivery summaries remain governed by Router and Deliver and do not load this Skill.

Read `./engifoundry.config.json`, the project-owned workspace guide, the user's requested subject, and only the primary records and artifacts needed for that subject. Derive the audience, language, depth, file type, and destination from the request and project conventions. When unspecified, use the user's language, Markdown, and the closest matching project-owned documentation or artifact location.

## Fidelity

- State project facts from current primary records and cite their paths where useful.
- Distinguish observed facts, accepted decisions, risks, open questions, and recommendations.
- Surface conflicting or missing evidence instead of resolving it by invention.
- Preserve exact code, commands, configuration, identifiers, and status terms when precision matters.
- Summarize source JSON and evidence; do not dump records, raw logs, prompts, or reasoning.

## Human Format

Organize around what the intended reader needs to understand or do. Use a literal title and descriptive section headings; include a short summary only when it improves navigation. Match structure to content rather than forcing a fixed template:

- tables for comparisons, status matrices, inventories, or repeated fields;
- bullet lists for unordered facts and numbered lists for actual sequences;
- fenced code blocks for code, commands, configuration, schemas, or exact output;
- blockquotes for material warnings, constraints, or quoted source decisions;
- short paragraphs for explanation, causality, and conclusions.

Use direct, concrete wording. Explain necessary domain terms for the intended audience, keep each section internally coherent, and avoid duplicated conclusions, decorative prose, empty headings, and oversized tables. Risk statements name severity, fact, impact, and evidence. Recommendations identify their factual basis and never masquerade as completed work.

## Completion

Check that the document answers the explicit request, reflects the latest applicable records, uses the requested format, resolves internal links and references where possible, and remains readable without opening every source record. Report the output path and any evidence limitation concisely.
