# Sprint 1 — Backend Foundation

## Goal
Deliver the first vertical slice: a learner can discover an arena and mission, submit a structured challenge answer, receive deterministic scoring, and become eligible for XP.

## Locked MVP scope
- Arenas: Cloud, Cyber, Networking, Data
- Formats: Knowledge, Scenario, Practical
- Automatic deterministic scoring first
- AI feedback later
- Labs later
- XP and achievements
- No arbitrary learner code execution in the MVP

## Work sequence
1. Backend scaffold, configuration, health endpoint and local PostgreSQL.
2. Apply the approved PostgreSQL v1.1 schema and seed all four arenas.
3. Mission catalogue read APIs that never expose answer keys or evaluation rules.
4. Version-pinned challenge attempts and deterministic evaluator registry.
5. Knowledge, Scenario and Practical evaluators with golden test cases.
6. Transactional scoring, first-pass XP ledger entries and achievement unlocks.
7. API tests, security review and developer documentation.

## Definition of done for Sprint 1
- Clean local setup from documented steps.
- Database migration applies to a fresh PostgreSQL database.
- Four arenas are returned by the API.
- Published mission versions are immutable and attempts pin a version.
- Learner APIs never return private evaluation configuration.
- Duplicate submission/retry cannot award XP more than once.
- Scoring is deterministic and covered by automated tests.

## Explicitly deferred
Labs, AI-generated feedback, multiplayer, payments, arbitrary code execution and production deployment.
