# Documentation Index — backend_sinicerita

> **For AI Assistants**: This file is the primary entry point for understanding the SiniCerita backend codebase. Read this file first to determine which detailed documentation files to consult for specific questions.

## Quick Context

SiniCerita is a **mental health chatbot REST API** built with Express 5 + Prisma + Google Gemini AI. Users chat with AI personas, sessions are analyzed for emotional state, and health points (0–100) are tracked.

## Documentation Files

| File | Purpose | Consult When... |
|------|---------|-----------------|
| [codebase_info.md](./codebase_info.md) | Project identity, tech stack, scripts | You need project metadata, tech choices, or how to run the app |
| [architecture.md](./architecture.md) | System design, layer responsibilities, flows | You need to understand how components connect or the request pipeline |
| [components.md](./components.md) | Major components, their files, and behaviors | You need to find where specific functionality lives |
| [interfaces.md](./interfaces.md) | API endpoints, request/response formats | You need endpoint details, auth requirements, or response shapes |
| [data_models.md](./data_models.md) | Database schema, entities, relationships | You need to understand data structure, constraints, or relationships |
| [workflows.md](./workflows.md) | Step-by-step process flows with diagrams | You need to understand how a feature works end-to-end |
| [dependencies.md](./dependencies.md) | External packages and services | You need to know what's installed, env vars, or external integrations |

## Key Facts for AI Assistants

- **Language**: JavaScript ESM (`"type": "module"`) — use `import`/`export`, not `require`
- **Framework**: Express 5 (supports async route handlers natively)
- **Database**: PostgreSQL via Prisma — schema at `prisma/schema.prisma`
- **AI**: Google Gemini via `@google/genai` SDK — model: `gemini-2.5-flash`
- **Auth**: JWT access tokens + single-use refresh tokens (7-day expiry)
- **Validation**: Zod schemas in `src/validators/`
- **Error pattern**: Services throw `{ statusCode, message }` objects
- **Response format**: `{ success, message, data }` envelope via `src/utils/response.js`
- **Language of responses**: Indonesian (Bahasa Indonesia) for user-facing messages
- **Roles**: `user` (default) and `admin` (persona management)
- **API source of truth**: live Swagger spec at `GET /api/docs` (UI) / `GET /api/docs.json` (raw OpenAPI 3.0). When in doubt about endpoints, fetch the live spec rather than trusting the `swagger_output.json` file at repo root.

## File Navigation Guide

```
src/app.js                    → Entry point, middleware + route mounting
src/routes/*.routes.js        → Route definitions + Swagger JSDoc
src/controllers/*.controller.js → Request handling + validation
src/services/*.service.js     → Business logic + DB operations
src/validators/*.schema.js    → Zod validation schemas
src/middlewares/              → Auth, role, upload, rate-limit, error handler
src/config/                   → Singleton clients (db, gemini, email, swagger)
src/utils/                    → JWT, OTP, response helpers
prisma/schema.prisma          → Database schema (source of truth for models)
```

## Cross-Reference Guide

- **Adding a new endpoint**: See [components.md](./components.md) for the layer pattern, [interfaces.md](./interfaces.md) for existing conventions
- **Understanding auth**: See [workflows.md](./workflows.md) for token flows, [architecture.md](./architecture.md) for middleware chain
- **Modifying data models**: See [data_models.md](./data_models.md) for schema, then run `prisma migrate dev`
- **Adding external services**: See [dependencies.md](./dependencies.md) for env var patterns and config setup
- **Understanding AI behavior**: See [workflows.md](./workflows.md) for Gemini integration, [components.md](./components.md) for Gemini Service details
