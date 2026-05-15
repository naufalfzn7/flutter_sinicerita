# Data Models

## Entity Relationship Diagram

```mermaid
erDiagram
    User ||--o{ Session : "has"
    User ||--o{ RefreshToken : "has"
    User ||--o{ Persona : "creates"
    User ||--o{ PersonaRating : "rates"
    Persona ||--o{ Session : "used in"
    Persona ||--o{ PersonaRating : "receives"
    Session ||--o{ Message : "contains"

    User {
        uuid id PK
        varchar name
        varchar email UK
        varchar password
        enum role
        int points
        string avatarUrl
        datetime createdAt
        datetime updatedAt
    }

    Persona {
        uuid id PK
        varchar name
        text description
        text systemPrompt
        string avatarUrl
        boolean isActive
        int upvotes
        int downvotes
        uuid createdById FK
        datetime createdAt
        datetime updatedAt
    }

    Session {
        uuid id PK
        uuid userId FK
        uuid personaId FK
        enum status
        int scoreDelta
        text analysisSummary
        datetime startedAt
        datetime completedAt
        datetime createdAt
    }

    Message {
        uuid id PK
        uuid sessionId FK
        enum role
        text content
        datetime createdAt
    }

    RefreshToken {
        uuid id PK
        uuid userId FK
        string token UK
        datetime expiresAt
        datetime createdAt
    }

    OtpCode {
        uuid id PK
        varchar email
        varchar code
        datetime expiresAt
        boolean used
        datetime createdAt
    }

    PersonaRating {
        uuid id PK
        uuid userId FK
        uuid personaId FK
        enum type
        datetime createdAt
        datetime updatedAt
    }
```

## Enums

| Enum | Values (Prisma) | Usage |
|------|-----------------|-------|
| `Role` | `user`, `admin` | User access level |
| `SessionStatus` | `active`, `completed` | Session lifecycle state |
| `MessageRole` | `user`, `model` | Message sender type (Gemini SDK uses `model` for AI replies) |
| `RatingType` | `UP`, `DOWN` | Persona rating direction (stored values only) |

> **API note**: The `POST /api/personas/:id/rate` endpoint also accepts `NONE` as a `type` value, but `NONE` is **not** a Prisma enum value — the service interprets it as "remove this user's rating row".

## Model Details

### User
- Points range: 0–100 (clamped on update)
- Default avatar: Cloudinary-hosted generic profile image
- Cascade: deleting user cascades to sessions, refresh tokens, ratings

### Persona
- Soft-deleted via `isActive` flag
- `systemPrompt`: injected as Gemini system instruction
- `upvotes`/`downvotes`: denormalized counters updated in transaction
- Default avatar: Cloudinary-hosted psychologist image
- Unique constraint: one rating per user per persona (`@@unique([userId, personaId])`)

### Session
- Owned by a single user (enforced at service layer; 403 on mismatch)
- `scoreDelta`: set on completion, clamped to `[-20, +20]` by the analysis service
- `analysisSummary`: Gemini-generated emotional analysis text
- Completed sessions cannot be deleted (DELETE returns 400) and cannot be re-completed (PATCH `/complete` returns **409**)
- Cascade: deleting session cascades to messages

### Message
- Ordered by `createdAt ASC`
- AI replies created 1ms after user message (ensures ordering)
- No edit/delete capability

### RefreshToken
- Single-use: deleted on refresh or logout
- 7-day expiry
- Cascade: deleted when user is deleted

### OtpCode
- 6-digit numeric code
- 10-minute expiry
- `used` flag prevents reuse
- Not linked by FK to User (uses email match)

### PersonaRating
- Unique per user-persona pair (`@@unique([userId, personaId])`)
- `type` is `RatingType` (`UP` or `DOWN` only)
- API supports a `NONE` action that **deletes** the row instead of storing it
- Aggregate counters (`upvotes`, `downvotes`) on `Persona` are updated in the same transaction

## Database Configuration

- Provider: PostgreSQL
- ORM: Prisma 5.22
- Connection: `DATABASE_URL` (pooled), `DIRECT_URL` (direct)
- Table naming: snake_case via `@@map()`
- Column naming: snake_case via `@map()`
