# Home School Logs - Sync Architecture

This document covers the sync strategy, real-time options, and scaling considerations for the Home School Logs app.

---

## 📊 Current Sync Implementation

### Strategy: Offline-First with Push/Pull Sync

The mobile app uses **Hive** (local storage) as the primary data source, with periodic sync to the server:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Flutter App   │ ──▶ │   Go Backend     │ ──▶ │    MongoDB      │
│   (Hive DB)     │ ◀── │   (REST API)     │ ◀── │   (Cloud)       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                        
    Local-first            JWT Auth                  
    needsSync=true       since= param              
```

### Sync Flow

1. **Push Phase**: Send all local records with `needsSync=true` to server
2. **Pull Phase**: Fetch records updated since last sync (incremental)
3. **Merge**: Server-wins conflict resolution based on `updatedAt`
4. **Update Metadata**: Record `lastFullSync` timestamp

### When Sync Occurs

| Trigger | Type | Notes |
|---------|------|-------|
| User login | Full sync | Push + Pull all data |
| Dashboard load | Incremental | Only changes since last sync |
| Manual "Sync Now" | Full sync | User-initiated from Settings |
| Data change (planned) | Push-only | Immediate push when online |

### Incremental Sync (since parameter)

To prevent syncing ALL data on every sync (which doesn't scale), endpoints support a `since` query parameter:

```
GET /api/v1/students?since=2025-12-09T10:00:00Z
GET /api/v1/subjects?since=2025-12-09T10:00:00Z
GET /api/v1/logs?since=2025-12-09T10:00:00Z
```

This returns only records where `updatedAt > since`, reducing bandwidth and server load dramatically.

---

## 🔄 Real-Time Sync Options

### Goal
Allow users on multiple devices (mobile, web) to see changes from each other without manual refresh, while keeping infrastructure simple and costs low.

### Option Comparison

| Option | Latency | Bi-directional | Scalability | Complexity | Cost |
|--------|---------|----------------|-------------|------------|------|
| **Polling** | 1-5 min | ✅ Yes | ⭐⭐⭐⭐ | Low | Free |
| **Long Polling** | 1-30s | ✅ Yes | ⭐⭐⭐ | Medium | Free |
| **SSE** | Real-time | ❌ Server→Client | ⭐⭐⭐ | Medium | Free |
| **WebSockets** | Real-time | ✅ Yes | ⭐⭐ | High | Free |
| **Push Notifications** | 1-10s | ❌ Server→Client | ⭐⭐⭐⭐⭐ | Medium | Firebase (free tier) |
| **PubNub/Pusher** | Real-time | ✅ Yes | ⭐⭐⭐⭐⭐ | Low | $$$ (hosted) |

---

### Option 1: Polling (Simplest)

**How it works**: Client periodically calls the server to check for changes.

```dart
// Every 5 minutes, check for updates
Timer.periodic(Duration(minutes: 5), (_) {
  syncService.performFullSync(incremental: true);
});
```

**Pros**:
- Dead simple to implement
- Works everywhere (all browsers, all networks)
- No persistent connections to manage
- Scales easily with horizontal load balancing

**Cons**:
- Not real-time (minimum latency = poll interval)
- Wasted requests when nothing changed
- More bandwidth usage at scale

**Scale Analysis**:
- 10,000 users × 1 request/5 min = 33 req/sec → ✅ Easy for Go
- 100,000 users × 1 request/5 min = 333 req/sec → ✅ Manageable with caching

**Recommendation**: Good for v1. Simple and reliable.

---

### Option 2: Long Polling

**How it works**: Client makes a request, server holds it open until data changes or timeout.

```go
// Server holds connection until:
// 1. Data changes for this family
// 2. 30 second timeout
func (h *SyncHandler) WaitForChanges(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 30*time.Second)
    defer cancel()
    
    changes := waitForFamilyChanges(ctx, familyID)
    if changes != nil {
        JSON(w, http.StatusOK, changes)
    } else {
        JSON(w, http.StatusNoContent, nil)
    }
}
```

**Pros**:
- Near real-time (changes detected immediately)
- Falls back gracefully to normal HTTP
- Works through most proxies/firewalls

**Cons**:
- Holds connections open (more server resources)
- Requires coordination to detect changes (Redis pub/sub, etc.)
- More complex than simple polling

**Scale Analysis**:
- Connections held = active users (not total users)
- 10K concurrent connections → ~100MB RAM → ✅ Fine
- 100K concurrent → Need horizontal scaling with Redis pub/sub

---

### Option 3: Server-Sent Events (SSE)

**How it works**: Client opens a long-lived HTTP connection, server pushes events.

```go
// Server pushes events to connected clients
func (h *StreamHandler) Stream(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    
    for {
        select {
        case change := <-familyChanges:
            fmt.Fprintf(w, "event: %s\ndata: %s\n\n", change.Type, change.ID)
            w.(http.Flusher).Flush()
        case <-r.Context().Done():
            return
        }
    }
}
```

```dart
// Flutter client (using EventSource package)
EventSource.connect('$baseUrl/api/v1/stream').listen((event) {
  if (event.event == 'log_created') {
    // Fetch the specific record
    syncService.pullSingleLog(event.data);
  }
});
```

**Pros**:
- True real-time server→client
- Standard HTTP (works through proxies)
- Auto-reconnect built into browser EventSource API
- Lower overhead than WebSockets

**Cons**:
- One-way only (server→client)
- Still need POST for client→server changes
- Persistent connections use server resources

**Scale Analysis**:
- Each connection ~10KB RAM
- 10K users = 100MB RAM → ✅ Easy
- 100K users = 1GB RAM → Needs horizontal scaling with Redis pub/sub

**Bi-directional Solution**: Combine SSE (for push) with REST POST (for changes). Server pushes "something changed" event, client fetches the specific record.

---

### Option 4: WebSockets

**How it works**: Full duplex TCP connection with message framing.

```dart
// Flutter client
final channel = WebSocketChannel.connect(Uri.parse('ws://server/ws'));

// Send changes
channel.sink.add(jsonEncode({'type': 'log_created', 'data': log}));

// Receive changes
channel.stream.listen((message) {
  final event = jsonDecode(message);
  handleServerEvent(event);
});
```

**Pros**:
- True bi-directional real-time
- Lowest latency
- Efficient for high-frequency updates

**Cons**:
- More complex connection management
- Some proxies/firewalls block WebSockets
- Requires sticky sessions or Redis pub/sub for scaling
- Connection state management is tricky

**Scale Analysis**:
- Similar to SSE, but more complex
- Requires WebSocket-aware load balancer
- Redis pub/sub needed for multi-server

**Recommendation**: Overkill for this app. Log entries are created ~10-50 times/day per family.

---

### Option 5: Push Notifications + Sync

**How it works**: Server sends push notification saying "data changed", app wakes up and syncs.

```go
// When log is created on server
func (h *LogHandler) Create(...) {
    // ... create log ...
    
    // Send FCM notification to family devices
    fcm.SendToTopic(fmt.Sprintf("family-%s", familyID), messaging.Message{
        Data: map[string]string{"type": "sync_needed"},
    })
}
```

```dart
// Flutter handles background notification
FirebaseMessaging.onBackgroundMessage((message) {
  if (message.data['type'] == 'sync_needed') {
    syncService.performFullSync(incremental: true);
  }
});
```

**Pros**:
- Works when app is backgrounded/closed
- Battery efficient (no persistent connection)
- Firebase/APNs handle the hard parts
- Infinite scale (push services handle it)

**Cons**:
- Not guaranteed delivery
- Variable latency (1-10 seconds typical)
- Requires Firebase setup for Android, APNs for iOS
- Can't use for web (need SSE/WS fallback)

**Recommendation**: Great addition for mobile background sync, but need fallback for web.

---

## 🎯 Recommended Architecture

### Phase 1: Current (v1.0)
- **Sync Trigger**: Login, dashboard load, manual
- **Sync Type**: Incremental with `since` parameter
- **Real-time**: None (user must refresh/navigate)

### Phase 2: Auto-Push (v1.1) ✅ **COMPLETED**
- **On data change**: Immediately push to server if online
- **Offline indicator**: Show when not connected
- **Debounced sync**: Coalesce rapid changes (2 second debounce)

**Implementation Details (Dec 10, 2025)**:
- `AutoSyncService`: Debounced auto-push with 2 second delay after changes
- `ConnectivityService`: Monitors network state via connectivity_plus
- `OfflineIndicator` widget: Shows amber banner when offline
- All CRUD providers (logs, students, subjects) notify AutoSyncService on changes
- Auto-sync when coming back online with pending changes

### Phase 3: Background Sync (v1.2)
- **Push notifications**: FCM/APNs notify when data changes
- **Background sync**: App syncs even when closed
- **Web fallback**: Polling every 5 minutes

### Phase 4: Real-Time (v2.0) - If Needed
- **SSE for web/mobile**: Server pushes change events
- **Redis pub/sub**: Multi-server coordination
- **Smart client**: Only fetch changed records

---

## 📈 Scaling Considerations

### MongoDB Indexes

Ensure these indexes exist for efficient `since` queries:

```javascript
// Already indexed by familyId, add compound with updatedAt
db.students.createIndex({ familyId: 1, updatedAt: 1 })
db.subjects.createIndex({ familyId: 1, updatedAt: 1 })
db.log_entries.createIndex({ familyId: 1, updatedAt: 1 })
```

### Sync Load Estimation

Typical family data:
- Students: 1-5 records
- Subjects: 8-20 records
- Log entries: 50-200 per school year, 500-1000 lifetime

With incremental sync:
- First login: Pull all data (~50KB typical)
- Subsequent syncs: Only changes (~1-5KB typical)

### Server Capacity (Single VPS)

A modest VPS (4 vCPU, 8GB RAM) can handle:
- Go server: 5,000-10,000 concurrent requests/sec
- MongoDB: 10,000+ concurrent connections
- SSE/WebSocket: 50,000+ concurrent connections

This supports:
- 100,000+ registered families easily
- 10,000+ concurrent active users
- No paid services needed

---

## 🔐 Sync Security

### Data Isolation
- All sync endpoints filter by `familyId`
- JWT tokens include `familyId` claim
- Server validates family membership

### Token Refresh
- Access tokens: 15 minutes
- Refresh tokens: 7 days (configurable to 30)
- Auto-refresh on 401 response

### Conflict Resolution
- Server-wins (last-write-wins) based on `updatedAt`
- Client marks `needsSync=false` after successful push
- Merge on pull preserves local changes if newer

---

## 📝 API Reference

### Students
```
GET /api/v1/students
GET /api/v1/students?since=2025-12-09T10:00:00Z
```

### Subjects
```
GET /api/v1/subjects
GET /api/v1/subjects?since=2025-12-09T10:00:00Z
```

### Log Entries
```
GET /api/v1/logs
GET /api/v1/logs?since=2025-12-09T10:00:00Z
GET /api/v1/logs?studentId=xxx&startDate=2025-01-01&endDate=2025-12-31
```

### Sync Metadata (Future)
```
GET /api/v1/sync/status
  → { lastChange: "2025-12-09T10:30:00Z", counts: { students: 2, logs: 150 } }
```

---

*Last Updated: December 9, 2025*
