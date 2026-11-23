# Contract: Sign-in error responses (FR-018)

Endpoints are under `/api/v1/auth`. Success responses are unchanged. Only the error cases below change from **500** to a client error.

Error body (existing `ApiError`, unchanged shape; the frontend shows `message`):

```json
{ "status": 401, "error": "Unauthorized", "message": "Invalid email or password.", "timestamp": "2026-11-18T09:00:00Z" }
```

| Endpoint | Case | Before | After | `message` |
|---|---|---|---|---|
| `POST /login` | Unknown email | 500 | **401** | `Invalid email or password.` |
| `POST /login` | Wrong password | 500 | **401** | `Invalid email or password.` (identical, so it doesn't reveal whether the account exists) |
| `POST /register` | Email already registered | 500 | **409** | `An account with this email already exists.` No second user row is created |
| `POST /refresh` | No `refresh_token` cookie | 401 | 401 (unchanged) | `Refresh token not found` (unchanged) |
| `POST /refresh` | Cookie value unknown | 500 | **401** | `Your session has expired. Please sign in again.` |
| `POST /refresh` | Token revoked | 500 | **401** | same as above |
| `POST /refresh` | Token expired (expiry < `clock.instant()`) | 500 | **401** | same as above |
| `POST /refresh` | Token's user no longer exists | 500 | **401** | same as above |

Rules:
- No message contains a stack trace, SQL, class name or the email address.
- Status reason phrases (`error`) come from `GlobalExceptionHandler.reasonFor`, unchanged.
- Known issues **not** changed by F008 (filed as bugs): refresh tokens expire after the access-token lifetime (15 min) instead of 7 days, and logout doesn't revoke the stored refresh token.

## Bad bearer token on any protected endpoint (added during implementation, T038)

| `Authorization` header | Before | After |
|---|---|---|
| Missing, or not `Bearer …` | 401, empty body | 401, `ApiError` body (FR-020) |
| `Bearer <malformed>` | 500 (JWT exception escaped `JwtAuthenticationFilter`) | **401** |
| `Bearer <valid token with tampered signature>` | 500 | **401** |
| `Bearer <token signed with another key>` | 500 | **401** |

The filter now treats an unreadable token as "not signed in". The security entry point then answers 401 as for a missing token, with the shared error body (it was empty before FR-020):

```json
{ "status": 401, "error": "Unauthorized", "message": "Please sign in to continue.", "timestamp": "…" }
```

Verified by `component/SignInComponentTest` (one test per sign-in row) and `integration/JwtSecurityIntegrationTest` (bearer-token rows).
