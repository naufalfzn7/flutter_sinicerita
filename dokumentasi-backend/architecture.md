# Architecture

## System Overview

```mermaid
graph TB
    Client[Client App] -->|HTTP| Express[Express 5 Server]
    Express --> RateLimit[Rate Limiter]
    RateLimit --> Routes[Route Layer]
    Routes --> Auth[Auth Middleware]
    Auth --> Controllers[Controller Layer]
    Controllers --> Services[Service Layer]
    Services --> Prisma[Prisma ORM]
    Services --> Gemini[Google Gemini AI]
    Services --> Email[Nodemailer]
    Services --> Cloud[Cloudinary]
    Prisma --> DB[(PostgreSQL)]
```

## Layered Architecture

```mermaid
graph LR
    subgraph "Request Pipeline"
        R[Routes] --> M[Middlewares]
        M --> C[Controllers]
        C --> S[Services]
        S --> D[Data Layer / Prisma]
    end
```

### Layer Responsibilities

| Layer | Location | Responsibility |
|-------|----------|---------------|
| Routes | `src/routes/` | HTTP method binding, Swagger annotations, middleware chaining |
| Middlewares | `src/middlewares/` | Auth, role checks, rate limiting, file upload, error handling |
| Controllers | `src/controllers/` | Request parsing, Zod validation, response formatting |
| Services | `src/services/` | Business logic, DB operations, external API calls |
| Config | `src/config/` | Singleton clients (Prisma, Gemini, Email, Swagger) |
| Utils | `src/utils/` | JWT helpers, OTP generation, response formatters |
| Validators | `src/validators/` | Zod schemas for request validation |

## Design Patterns

- **Error-as-object**: Services throw `{ statusCode, message }` objects; the global error handler catches them
- **Soft delete**: Personas use `isActive` flag instead of hard delete
- **Token rotation**: Refresh tokens are single-use; each refresh issues a new pair
- **Transaction-heavy**: Critical operations (scoring, rating, token rotation) use `prisma.$transaction`
- **Pagination**: All list endpoints support `page`/`limit` with metadata response

## Authentication Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant A as Auth Routes
    participant S as Auth Service
    participant DB as PostgreSQL

    C->>A: POST /api/auth/login
    A->>S: loginUser(credentials)
    S->>DB: Find user by email
    S->>S: Verify bcrypt password
    S->>DB: Store refresh token
    S-->>C: { accessToken, refreshToken, user }

    C->>A: POST /api/auth/refresh
    A->>S: refreshAuthToken(refreshToken)
    S->>DB: Find & delete old token
    S->>DB: Create new refresh token
    S-->>C: { accessToken, refreshToken }
```

## AI Integration Flow

```mermaid
sequenceDiagram
    participant U as User
    participant API as Session Controller
    participant GS as Gemini Service
    participant AI as Google Gemini
    participant DB as PostgreSQL

    U->>API: POST /api/sessions/:id/messages
    API->>DB: Load message history
    API->>GS: getChatReply(systemPrompt, history, message)
    GS->>AI: generateContent(systemInstruction + context)
    AI-->>GS: AI response text
    GS-->>API: Cleaned response
    API->>DB: Save user message + AI reply
    API-->>U: { userMessage, aiReply }

    U->>API: PATCH /api/sessions/:id/complete
    API->>DB: Load all messages
    API->>GS: analyzeSession(messages)
    GS->>AI: Analyze emotional state (JSON output)
    AI-->>GS: { delta, summary }
    GS-->>API: Clamped delta [-20,+20]
    API->>DB: Update session + user points
    API-->>U: { session, scoreDelta, newPoints, summary }
```

## Directory Structure

```
backend_sinicerita/
├── src/
│   ├── app.js                 # Entry point
│   ├── config/                # Singleton configs
│   │   ├── db.js              # Prisma client
│   │   ├── gemini.js          # Gemini AI client
│   │   ├── email.js           # Nodemailer transporter
│   │   └── swagger.js         # Swagger spec
│   ├── controllers/           # Request handlers
│   ├── middlewares/           # Auth, role, upload, errors
│   ├── routes/                # Express routers + Swagger docs
│   ├── services/              # Business logic
│   ├── utils/                 # JWT, OTP, response helpers
│   └── validators/            # Zod schemas
├── prisma/
│   ├── schema.prisma          # Database schema
│   └── migrations/            # Migration history
├── package.json
└── swagger_output.json        # Generated Swagger spec
```
