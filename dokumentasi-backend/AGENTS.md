# AGENTS.md

<!-- tags: ai-context, codebase-navigation, backend, express, prisma, gemini -->

> Concise navigation guide for AI agents working on the SiniCerita backend.

## Project Summary

Mental health chatbot REST API. Users chat with AI personas (Google Gemini), sessions are analyzed for emotional state changes (score delta -20 to +20), and health points (0–100) are tracked per user.

**Stack**: Express 5 · Prisma · PostgreSQL · Google Gemini · Zod · JWT · Nodemailer · Cloudinary

## Directory Map

```
src/
├── app.js                     # Entry point — mounts routes, middleware, Swagger
├── config/
│   ├── db.js                  # Prisma client singleton
│   ├── gemini.js              # Gemini AI client + model config
│   ├── email.js               # Nodemailer transporter (Gmail SMTP)
│   └── swagger.js             # Swagger spec generation
├── routes/                    # Express routers + Swagger JSDoc annotations
│   ├── auth.routes.js         # /api/auth/*
│   ├── me.routes.js           # /api/me/*
│   ├── persona.routes.js      # /api/personas/*
│   ├── session.routes.js      # /api/sessions/*
│   └── ping.routes.js         # / (health check)
├── controllers/               # Request parsing, Zod validation, response formatting
├── services/                  # Business logic, DB ops, external API calls
│   ├── auth.service.js        # Registration, login, token rotation, OTP
│   ├── session.service.js     # Session CRUD, messaging, completion + scoring
│   ├── persona.service.js     # Persona CRUD, rating system
│   ├── gemini.service.js      # AI chat reply + session emotional analysis
│   └── email.service.js       # OTP + welcome email templates
├── middlewares/
│   ├── auth.js                # JWT verification → sets req.user
│   ├── role.js                # requireRole(role) guard
│   ├── upload.js              # Multer + Cloudinary storage
│   ├── rate-limiter.js        # express-rate-limit config
│   └── error-handler.js       # Global error catch
├── validators/                # Zod schemas (auth, persona, session)
└── utils/                     # JWT gen/verify, OTP gen, response helpers
prisma/
├── schema.prisma              # Source of truth for data models
└── migrations/                # Migration history
```

## Key Patterns (Non-Default)

<!-- tags: patterns, conventions -->

- **ESM only** — `"type": "module"` in package.json. Use `import`/`export`.
- **Error throwing** — Services throw `{ statusCode, message }` objects. The global error handler middleware catches and formats them.
- **Response envelope** — All responses use `{ success, message, data }` via `src/utils/response.js`.
- **Indonesian messages** — User-facing error/success messages are in Bahasa Indonesia.
- **Soft delete** — Personas use `isActive` flag. Completed sessions cannot be deleted.
- **Token rotation** — Refresh tokens are single-use. Each refresh deletes old + creates new.
- **Points clamping** — User points always stay within 0–100 after session scoring.
- **Score delta** — Gemini analysis returns -20 to +20, clamped before storage.
- **Transaction-heavy** — Rating, scoring, token rotation, and password reset all use `prisma.$transaction`.

## Adding a New Feature

1. Define Zod schema in `src/validators/`
2. Create service function in `src/services/`
3. Create controller in `src/controllers/` (validate → call service → format response)
4. Add route in `src/routes/` with Swagger JSDoc and appropriate middleware chain
5. Mount route in `src/app.js` if new router
6. Add Prisma model/migration if new data needed

## Auth & Roles

- **Public**: register, login, refresh, forgot-password, verify-otp, reset-password
- **Authenticated** (Bearer token): all `/api/me`, `/api/sessions`, GET `/api/personas`
- **Admin only**: POST `/api/personas`, PATCH `/api/personas/:id`, DELETE `/api/personas/:id`
- Middleware chain: `authenticate` → `requireRole("admin")` for admin routes
- Rate limit on `/api/auth/*`: 10 requests per 15 minutes per IP (returns 429)

## HTTP Method Cheatsheet

| Method | Used for | Examples |
|--------|----------|----------|
| GET | Read | `/api/me`, `/api/personas`, `/api/sessions/:id/messages` |
| POST | Create / actions / send | `/api/auth/*`, `/api/personas`, `/api/sessions`, `/api/sessions/:id/messages`, `/api/personas/:id/rate` |
| PATCH | Partial update | `/api/me`, `/api/me/password`, `/api/personas/:id`, `/api/sessions/:id/complete` |
| DELETE | Remove | `/api/personas/:id` (soft), `/api/sessions/:id` (hard, active only) |

> The live OpenAPI spec at `GET /api/docs.json` (UI at `/api/docs`) is the source of truth. Never use `PUT` — none of the endpoints accept it.

## External Services & Config

| Service | Env Vars | Notes |
|---------|----------|-------|
| PostgreSQL | `DATABASE_URL`, `DIRECT_URL` | Prisma pooled + direct connections |
| Google Gemini | `GEMINI_API_KEY`, `GEMINI_MODEL` | Default model: gemini-2.5-flash |
| Cloudinary | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Avatar uploads |
| Gmail SMTP | `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM` | OTP emails |
| JWT | `JWT_SECRET`, `JWT_EXPIRES_IN` | Access token signing |

## Known Issues

- Dual Gemini SDK installed (`@google/genai` used, `@google/generative-ai` likely removable)
- `sendWelcomeEmail` defined but not called in registration flow
- No test framework configured (test scripts at root use raw axios)
- CORS allows all origins (no production allowlist)

## Detailed Documentation

Full documentation available at `.agents/summary/`:
- `index.md` — Knowledge base entry point with navigation guide
- `architecture.md` — System design and request pipeline
- `components.md` — Component inventory with file mappings
- `interfaces.md` — Complete API endpoint reference
- `data_models.md` — Database schema and entity relationships
- `workflows.md` — Step-by-step process flows with Mermaid diagrams
- `dependencies.md` — Package inventory and env var reference

## Custom Instructions
<!-- This section is for human and agent-maintained operational knowledge.
     Add repo-specific conventions, gotchas, and workflow rules here.
     This section is preserved exactly as-is when re-running codebase-summary. -->
