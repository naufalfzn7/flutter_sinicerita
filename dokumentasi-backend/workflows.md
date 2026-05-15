# Workflows

> All HTTP methods below match the live Swagger spec at `/api/docs`.

## User Registration Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant API as Auth Controller
    participant S as Auth Service
    participant DB as PostgreSQL
    participant E as Email Service

    C->>API: POST /api/auth/register {name, email, password}
    API->>API: Validate with Zod (registerSchema)
    API->>S: registerUser(data)
    S->>DB: Check email uniqueness
    alt Email exists
        S-->>API: throw 409 "Email already registered"
    end
    S->>S: bcrypt.hash(password, 12)
    S->>DB: Create user (role=user, points=0)
    S-->>API: user object
    API-->>C: 201 { success, data: user }
```

## Chat Session Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: POST /api/sessions
    Created --> Active: Session starts
    Active --> Active: POST /api/sessions/:id/messages
    Active --> Completed: PATCH /api/sessions/:id/complete
    Active --> Deleted: DELETE /api/sessions/:id
    Completed --> [*]: Cannot delete (400) or re-complete (409)
    Deleted --> [*]
```

## Send Message Workflow

```mermaid
sequenceDiagram
    participant C as Client
    participant SC as Session Controller
    participant SS as Session Service
    participant GS as Gemini Service
    participant AI as Gemini API
    participant DB as PostgreSQL

    C->>SC: POST /api/sessions/:id/messages {content}
    SC->>SS: sendSessionMessage(id, userId, content)
    SS->>DB: Verify session ownership & active status
    alt Session completed
        SS-->>SC: throw 400 "Sesi sudah selesai"
    end
    SS->>DB: Load message history (ordered by createdAt asc)
    SS->>GS: getChatReply(systemPrompt, history, content)
    GS->>GS: Build system instruction + context
    GS->>AI: generateContent(...)
    AI-->>GS: Raw text response
    GS->>GS: Clean markdown fences
    GS-->>SS: Clean AI reply
    SS->>DB: $transaction([create user msg, create AI msg])
    Note over SS,DB: AI message createdAt = userMessage createdAt + 1ms<br/>(ensures stable ordering)
    SS-->>SC: { userMessage, aiReply }
    SC-->>C: 200 { success, data }
```

## Session Completion & Scoring

```mermaid
sequenceDiagram
    participant C as Client
    participant SC as Session Controller
    participant SS as Session Service
    participant GS as Gemini Service
    participant AI as Gemini API
    participant DB as PostgreSQL

    C->>SC: PATCH /api/sessions/:id/complete
    SC->>SS: completeSession(sessionId, userId)
    SS->>DB: Verify ownership & active status
    alt Session already completed
        SS-->>SC: throw 409 "Sesi sudah selesai"
    end
    SS->>DB: Load all messages
    SS->>GS: analyzeSession(messages)
    GS->>GS: Build analysis prompt (psychologist role)
    GS->>AI: generateContent(analysis prompt)
    AI-->>GS: JSON { delta, summary }
    GS->>GS: Parse JSON, clamp delta to [-20, +20]
    GS-->>SS: { delta, summary }
    SS->>DB: $transaction:
    Note over SS,DB: 1. Read current user.points
    Note over SS,DB: 2. newPoints = clamp(points + delta, 0, 100)
    Note over SS,DB: 3. UPDATE session SET status='completed', scoreDelta, analysisSummary, completedAt=now()
    Note over SS,DB: 4. UPDATE user SET points = newPoints
    SS-->>SC: { session, newPoints }
    SC-->>C: 200 { session, scoreDelta, newPoints, summary }
```

## Password Reset (OTP) Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Auth Service
    participant DB as PostgreSQL
    participant E as Email Service

    C->>S: POST /api/auth/forgot-password {email}
    S->>DB: Verify user exists (404 if not)
    S->>S: Generate 6-digit OTP
    S->>DB: Store OTP (10-min expiry, used=false)
    S->>E: sendOTPEmail(email, code, name)
    E-->>C: 200 "OTP telah dikirim"

    C->>S: POST /api/auth/verify-otp {email, code}
    S->>DB: Find latest OTP for email
    S->>S: Check expiry & used flag
    S-->>C: 200 "OTP valid" or 400 if invalid

    C->>S: POST /api/auth/reset-password {email, code, newPassword}
    S->>DB: Re-validate OTP
    S->>S: bcrypt.hash(newPassword, 12)
    S->>DB: $transaction(update password, mark OTP used)
    S-->>C: 200 "Password berhasil direset"
```

## Token Refresh Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Auth Service
    participant DB as PostgreSQL

    C->>S: POST /api/auth/refresh {refreshToken}
    S->>DB: Find token record (include user)
    alt Token not found
        S-->>C: 401 "Refresh token tidak valid"
    end
    alt Token expired
        S->>DB: Delete expired token
        S-->>C: 401 "Refresh token expired"
    end
    S->>S: Generate new access token
    S->>S: Generate new refresh token
    S->>DB: $transaction(delete old token, create new token)
    S-->>C: 200 { accessToken, refreshToken }
```

## Persona Rating Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant PS as Persona Service
    participant DB as PostgreSQL

    C->>PS: POST /api/personas/:id/rate {type: UP|DOWN|NONE}
    PS->>DB: Verify persona exists (404 if not)
    PS->>DB: Find existing rating for (userId, personaId)
    PS->>PS: Compute counter deltas (undo old + apply new)
    PS->>DB: $transaction:
    Note over PS,DB: 1. UPDATE persona.upvotes/downvotes by deltas
    Note over PS,DB: 2. If type == "NONE" -> DELETE existing PersonaRating row
    Note over PS,DB: 3. Else -> UPSERT PersonaRating with type
    PS-->>C: 200 { message: "Rating berhasil disimpan" | "Rating berhasil dihapus" }
```

## Persona Soft-Delete Flow

```mermaid
sequenceDiagram
    participant C as Client (admin)
    participant PR as Persona Routes
    participant PS as Persona Service
    participant DB as PostgreSQL

    C->>PR: DELETE /api/personas/:id (Bearer admin token)
    PR->>PR: authenticate -> requireRole("admin")
    PR->>PS: deletePersona(id)
    PS->>DB: SELECT persona by id (404 if not found)
    PS->>DB: UPDATE persona SET isActive = false
    PS-->>C: 200 "Persona berhasil dihapus"
```

> Existing sessions referencing a soft-deleted persona remain accessible, but `GET /api/personas` only returns rows where `isActive = true`.
