# Review Notes

> Last validated against the live Swagger spec at `GET /api/docs.json` and source code in `src/routes/*.js`.

## Consistency Check ✅

| Area | Status | Notes |
|------|--------|-------|
| Tech stack references | ✅ Consistent | All docs reference Express 5, Prisma, Gemini, Zod consistently |
| API endpoint listing | ✅ Consistent | `interfaces.md` HTTP methods now match the live Swagger spec (PATCH for `/me`, `/me/password`, `/personas/:id`, `/sessions/:id/complete`) |
| Data model descriptions | ✅ Consistent | `data_models.md` matches `prisma/schema.prisma` exactly; clarified that `RatingType` is `UP`/`DOWN` only and `NONE` is an API-only action |
| Component file mappings | ✅ Consistent | `components.md` file paths verified against directory structure |
| Auth flow descriptions | ✅ Consistent | `workflows.md` and `architecture.md` describe the same token rotation pattern |
| Error handling pattern | ✅ Consistent | All docs reference `{ statusCode, message }` throw pattern |
| Scoring logic | ✅ Consistent | Delta `[-20, +20]` and points `[0, 100]` clamping documented uniformly |
| Session completion status | ✅ Consistent | 409 (already completed), 400 (cannot delete completed), 403 (not owner) documented in interfaces and workflows |

## Recent Corrections (this pass)

The following discrepancies were identified and fixed against the live Swagger spec:

| File | Issue | Resolution |
|------|-------|-----------|
| `interfaces.md` | Listed `PUT /api/me`, `PUT /api/me/password`, `PUT /api/personas/:id`, `POST /api/sessions/:id/complete` | Changed all to `PATCH` to match Swagger and route definitions |
| `interfaces.md` | Mermaid route map used `PUT` for personas/me | Replaced with `PATCH` |
| `interfaces.md` | Missing rate-limit threshold details | Added "10 requests / 15 min on `/api/auth/*`" note |
| `interfaces.md` | Missing pagination defaults | Added per-endpoint default `limit` table |
| `interfaces.md` | `/ping` shown as `/api/ping` | Corrected to root `/ping` (mounted before `/api/*` in `app.js`) |
| `workflows.md` | Session completion sequence used `POST` | Changed to `PATCH /api/sessions/:id/complete` |
| `workflows.md` | Did not mention 409 on re-complete | Added explicit alt-branch in sequence diagram |
| `architecture.md` | AI integration sequence used `POST` for complete | Changed to `PATCH` |
| `components.md` | Did not specify HTTP methods or `requireRole` chain | Method names + middleware chain now explicit |
| `data_models.md` | Said `RatingType: UP, DOWN` (correct) but `workflows.md` referenced `NONE` ambiguously | Clarified API-vs-Prisma enum split in both files |
| `dependencies.md` | Rate limiter specifics not documented | Added authLimiter window/max + CORS note |
| `AGENTS.md` | "POST/PUT/DELETE /api/personas" | Corrected to "POST/PATCH/DELETE" |

## Completeness Check

### Well-Documented Areas ✅
- Authentication & authorization flows
- Session lifecycle (create → message → complete with PATCH)
- Data models and relationships
- AI integration (chat + analysis with -20/+20 clamping)
- API endpoint inventory (now matching Swagger 1:1)
- Password reset OTP flow
- Persona rating system (UP/DOWN persisted, NONE deletes)
- Pagination meta on list endpoints

### Known Code-vs-Swagger Discrepancies ⚠️

These are implementation realities that differ slightly from the Swagger annotations:

| Endpoint | Swagger says | Actual code returns | Notes |
|----------|--------------|---------------------|-------|
| `PATCH /api/me/password` (wrong oldPassword) | `400` | `401` | Controller intentionally distinguishes "auth failure" from "validation failure" |
| `DELETE /api/sessions/:id` (already completed) | `400` | `400` | Matches |
| `PATCH /api/sessions/:id/complete` (already completed) | `409` | `409` | Matches |

### Other Gaps ⚠️

| Gap | Severity | Recommendation |
|-----|----------|---------------|
| No test framework configured | Medium | Project has only manual root-level test scripts. Consider Vitest or Jest. |
| Cloudinary upload constraints not documented | Low | `upload.js` middleware exists but folder/size/format constraints not explicit |
| CORS allowlist | Medium | Currently `cors()` with no options (allows all origins). Document/restrict for production |
| Deployment / CI configuration | Medium | No Dockerfile, no CI/CD config, no production env template |
| Centralized error codes catalog | Low | Error messages are in Bahasa Indonesia but no shared error code reference |
| Stale `swagger_output.json` at repo root | Info | The runtime spec (`/api/docs.json`) is generated fresh from JSDoc each request; the file at root may be outdated and unused |
| Dual Gemini SDK | Low | Both `@google/genai` and `@google/generative-ai` installed; only `@google/genai` is used |
| `sendWelcomeEmail` defined but not called | Info | Wire into registration flow or remove dead code |

### Language Support Limitations
- All source code is JavaScript — no TypeScript type definitions for deeper static analysis
- Swagger annotations in route files provide type information but are not machine-verified against controllers/services

## Recommendations

1. **Add a test framework** (Vitest recommended for ESM projects) and migrate root-level test scripts into proper test suites
2. **Reconcile `PATCH /api/me/password` 400/401 mismatch** — either update Swagger to document 401 for wrong old password, or return 400 from the controller
3. **Remove `@google/generative-ai`** if confirmed unused — reduces dependency surface
4. **Document Cloudinary upload constraints** in `upload.js` and the Swagger annotations
5. **Add CORS allowlist** for production deployment
6. **Wire up `sendWelcomeEmail`** in the registration flow or remove dead code
7. **Add Dockerfile** and basic CI/CD configuration for deployment readiness
8. **Delete or regenerate `swagger_output.json`** at repo root to avoid confusion with the live `/api/docs.json` spec
