# Codebase Information

## Project Identity

- **Name**: backend_sinicerita
- **Type**: REST API Backend
- **Domain**: Mental health chatbot platform
- **Language**: JavaScript (ESM)
- **Runtime**: Node.js
- **Framework**: Express 5.2.1

## Purpose

SiniCerita is a mental health support chatbot backend where users interact with AI personas powered by Google Gemini. Conversations are analyzed for emotional state changes, and users accumulate health points (0–100) based on session outcomes.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js (ESM modules) |
| Framework | Express 5 |
| Database | PostgreSQL |
| ORM | Prisma 5.22 |
| AI | Google Gemini (gemini-2.5-flash) |
| Auth | JWT (access + refresh tokens) |
| Validation | Zod 4 |
| File Upload | Multer + Cloudinary |
| Email | Nodemailer (Gmail SMTP) |
| Docs | Swagger (swagger-jsdoc + swagger-ui-express) |
| Rate Limiting | express-rate-limit |

## Key Characteristics

- All responses use Indonesian language (Bahasa Indonesia)
- ESM (`"type": "module"`) throughout — no CommonJS
- Layered architecture: routes → controllers → services → Prisma
- Error objects thrown as `{ statusCode, message }` — caught by error handler middleware
- Personas are soft-deleted (isActive flag)
- Completed sessions cannot be deleted (they affect user scores)
- User points clamped to 0–100 range
- Session analysis returns emotional delta between -20 and +20

## Entry Point

`src/app.js` — Express server setup, middleware registration, route mounting, Swagger docs.

## Scripts

| Script | Command |
|--------|---------|
| Start | `node src/app.js` |
| Dev | `nodemon src/app.js` |
| DB Generate | `prisma generate` |
| DB Migrate | `prisma migrate dev` |
| DB Deploy | `prisma migrate deploy` |
| DB Studio | `prisma studio` |
| DB Reset | `prisma migrate reset` |
