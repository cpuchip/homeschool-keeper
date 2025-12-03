# Tech Stack Decision

## Backend
- **Language**: Go 1.21+
- **Database**: MongoDB 7.x
- **API**: REST with OpenAPI 3.0 spec
- **Auth**: JWT + refresh tokens
- **Directory**: `/backend`

## Mobile App
- **Framework**: Flutter 3.x
- **Local Storage**: SQLite (sqflite) + Hive for preferences
- **State Management**: Riverpod
- **Directory**: `/mobile`

## Web Frontend
- **Framework**: Vue 3 + TypeScript
- **Build Tool**: Vite
- **State Management**: Pinia
- **UI Framework**: TailwindCSS + Headless UI
- **HTTP Client**: Axios with interceptors
- **Directory**: `/web`

## Sync Architecture
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Flutter App │◄───►│  Go API     │◄───►│  MongoDB    │
│ (SQLite)    │     │  Service    │     │  (Cloud)    │
└─────────────┘     └─────────────┘     └─────────────┘
     │                                        
     ▼                                        
  Local DB                                    
  (Offline)                                   
```

## Security Stack
- HTTPS/TLS everywhere
- AES-256 encryption at rest
- Bcrypt for passwords
- JWT with short expiry + refresh tokens
- Rate limiting
- Input validation/sanitization
