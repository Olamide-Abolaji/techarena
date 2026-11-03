# TechArena

**Learn. Compete. Prove Your Skills.**

TechArena is a gamified technology learning platform built around four arenas:

- Cloud Arena
- Cyber Arena
- Networking Arena
- Data Arena

## MVP scope

The first release focuses on challenges only. Labs are deferred.

### Challenge formats
1. **Knowledge Challenges** — objective questions with deterministic scoring.
2. **Scenario Challenges** — structured troubleshooting and decision-making tasks.
3. **Practical Challenges** — validated structured submissions. Arbitrary code execution is out of scope for the MVP.

## Locked MVP decisions

- All four arenas launch together.
- Automatic, deterministic scoring comes first.
- AI-generated feedback is deferred.
- Labs are deferred.
- XP and achievements are tied to challenge completion.

## Initial engineering direction

- Backend: Python + FastAPI
- Database: PostgreSQL
- Tests: pytest
- Local development: Docker Compose

## Sprint 1

Sprint 1 establishes the backend foundation and challenge engine. The detailed implementation plan and architecture decisions will live in `docs/`.

> This repository is under active development. Authentication enforcement, production deployment, observability, rate limiting, and security hardening must be completed before public launch.
