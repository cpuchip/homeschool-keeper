# Homeschool Keeper

📚 An offline-first app to help parents track, plan, and journal their children's homeschool education.

## Features

- **Quick Logging** - Log educational hours in under 30 seconds
- **Hour Tracking** - Track total, core, and at-home hours toward state requirements
- **Multi-Student** - Manage multiple children's education from one account
- **Subject Management** - Core subjects + custom electives
- **Work Samples** - Upload photos and documents of student work
- **Offline-First** - Full functionality without internet
- **Compliance Reports** - Generate reports for state requirements

## Tech Stack

- **Backend**: Go 1.25.5 + MongoDB 8.2
- **Frontend**: Vue 3 + TypeScript + Vite + TailwindCSS
- **Mobile**: Flutter 3.38 (coming soon)

## Project Structure

```
homeschool-keeper/
├── backend/                 # Go backend service
│   ├── auth/               # Authentication
│   ├── config/             # Configuration
│   ├── db/                 # Database
│   ├── frontend/           # Vue 3 frontend (embedded)
│   └── main.go             # Server entrypoint
├── mobile/                  # Flutter mobile app
├── docs/                    # Documentation
└── scripts/                 # Development scripts
```

## Quick Start

### Prerequisites

- Go 1.25+
- Node.js 22+
- MongoDB 8.2+ (or Docker)

### Development

1. **Clone and setup**
   ```bash
   git clone https://github.com/cpuchip/homeschool-keeper.git
   cd homeschool-keeper
   cp .env.example .env
   ```

2. **Start MongoDB** (if using Docker)
   ```bash
   docker-compose up -d mongo
   ```

3. **Install frontend dependencies**
   ```bash
   cd backend/frontend
   npm install
   ```

4. **Run development servers**
   ```bash
   # Terminal 1: Backend
   cd backend
   go run .

   # Terminal 2: Frontend (hot reload)
   cd backend/frontend
   npm run dev
   ```

5. **Open in browser**
   - Frontend dev server: http://localhost:5173
   - Backend API: http://localhost:8080

### Production Build

```bash
# Build frontend
cd backend/frontend
npm run build

# Build Go binary (includes embedded frontend)
cd ..
go build -o homeschool-keeper .

# Run
./homeschool-keeper
```

### Docker

```bash
# Build and run
docker-compose up --build

# Or just build the image
docker build -t homeschool-keeper .
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/homeschool-keeper` |
| `JWT_SECRET` | JWT signing secret | (required in production) |
| `DEV_MODE` | Enable dev features | `false` |

See `.env.example` for all options.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| GET | `/api/v1/students` | List students |
| POST | `/api/v1/logs` | Create log entry |
| ... | ... | See API docs |

## State Requirements

The app is designed to help families meet state homeschool requirements. For Missouri:

- **1,000 hours** total instruction per year
- **600 hours** in core subjects (Reading, Math, Social Studies, Language Arts, Science)
- **400 hours** at home location
- Maintain records: plan book, work samples, evaluations

## Deployment

The app is configured for deployment via Dokploy with GitHub Actions CI/CD:

1. Push to `main` branch
2. GitHub Actions builds and pushes Docker image to GHCR
3. Dokploy pulls and deploys the new image

See `dokploy.yml` for configuration.

## License

MIT
