# Tech Stack Decision

## Backend
- **Language**: Go 1.25.5
- **Database**: MongoDB 8.2
- **API**: REST with clean endpoints
- **Auth**: JWT + refresh tokens (local auth) + OAuth (future)
- **Router**: gorilla/mux
- **Directory**: `/backend`

## Web Frontend (embedded in backend)
- **Framework**: Vue 3 + TypeScript
- **Build Tool**: Vite 7.x
- **State Management**: Pinia
- **UI Framework**: TailwindCSS 3.x
- **Router**: Vue Router 4
- **Directory**: `/backend/frontend`
- **Deployment**: Built assets embedded/served by Go backend

## Mobile App
- **Framework**: Flutter 3.38
- **Local Storage**: SQLite (sqflite) + Hive for preferences
- **State Management**: Riverpod
- **Directory**: `/mobile`

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
