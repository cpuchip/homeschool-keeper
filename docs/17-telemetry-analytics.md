# Mobile App Telemetry & Analytics

## Purpose

Track anonymous usage metrics for the mobile app, especially for users who:
- Use the app without creating an account
- Don't enable sync (local-only mode)
- Want to evaluate the app before committing

This helps us understand:
- Is the app being used?
- Which features are popular?
- Where do users get stuck?
- App stability and crash rates

---

## Privacy Principles

### 1. Minimal Data Collection
Only collect what's necessary. No PII (Personally Identifiable Information).

### 2. Anonymous by Default
Use a random install ID, not tied to any user identity.

### 3. Transparent
Document what we collect in the privacy policy.

### 4. Opt-Out Available
Allow users to disable telemetry in settings.

### 5. No Child Data
Never collect data that could identify or profile children (students).

---

## Proposed Metrics

### Tier 1: Essential (Default On)

| Metric | Purpose | Privacy Risk |
|--------|---------|--------------|
| Install ID | Count unique installs | Low (random UUID) |
| App Version | Track adoption, deprecate old versions | None |
| Platform | iOS vs Android vs Windows | None |
| First Launch Date | Cohort analysis | Low |
| Last Active Date | Retention tracking | Low |
| App Crashes | Stability monitoring | Low |

### Tier 2: Usage (Default On, Opt-Out)

| Metric | Purpose | Privacy Risk |
|--------|---------|--------------|
| Screen Views | Which features are used | Low |
| Feature Usage Counts | What's popular | Low |
| Session Duration | Engagement level | Low |
| Onboarding Completion | Conversion funnel | Low |
| Account Created (bool) | Sync adoption rate | Low |
| Sync Enabled (bool) | Premium feature interest | Low |
| Export Generated (count) | Feature usage | Low |
| Work Sample Added (count) | Engagement with media features | Low |

### Tier 3: Aggregated (No Individual Data)

| Metric | Purpose | Privacy Risk |
|--------|---------|--------------|
| Student Count Range | App sizing (1-2, 3-5, 6+) | None (ranges, not exact) |
| Log Entry Count Range | Engagement level | None (ranges) |
| State (if provided) | Regional popularity | Low |

### What We Will NOT Collect

❌ Student names or identifying info
❌ Log entry descriptions or content
❌ Work sample data
❌ User emails or account details
❌ Location data (GPS)
❌ Device identifiers (IDFA, GAID)
❌ Contact lists or other app data
❌ Any data from children

---

## Technical Implementation

### Install ID Generation

```dart
// Generate on first launch, store locally
class TelemetryService {
  static const _installIdKey = 'telemetry_install_id';
  
  Future<String> getInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_installIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_installIdKey, id);
    }
    return id;
  }
}
```

### Event Schema

```json
{
  "installId": "uuid-v4",
  "appVersion": "1.2.3",
  "platform": "android",
  "event": "screen_view",
  "data": {
    "screen": "dashboard"
  },
  "timestamp": "2025-12-12T10:30:00Z"
}
```

### Collection Options

| Option | Pros | Cons |
|--------|------|------|
| **Self-hosted (recommended)** | Full control, privacy-friendly | More work |
| **Firebase Analytics** | Easy setup, powerful | Google data policies |
| **PostHog (self-hosted)** | Open source, full control | Hosting cost |
| **Mixpanel** | Good free tier | Cloud-based |
| **Amplitude** | Generous free tier | Cloud-based |

### Recommended: Self-Hosted Simple Endpoint

Create a minimal `/api/v1/telemetry` endpoint:
- Accepts anonymous events
- No authentication required
- Rate limited by install ID
- Data stored separately from user data

---

## Opt-Out Implementation

### Settings Screen Addition

```
📊 Analytics
Help improve the app by sharing anonymous usage data.
[Toggle: Share Usage Data]

We never collect personal information about you or your students.
Learn more →
```

### First Launch Prompt (Optional)

Consider asking on first launch:
> "Help us improve! Share anonymous usage stats?"
> [Yes, help out] [No thanks]

Note: Many apps skip this and just document in privacy policy.

---

## Events to Track

### Onboarding Funnel
1. `app_installed` - First launch
2. `onboarding_started` - Began setup
3. `onboarding_student_added` - Added first student
4. `onboarding_subject_selected` - Chose subjects
5. `onboarding_completed` - Finished setup
6. `account_created` - Created sync account
7. `sync_enabled` - Enabled cloud sync

### Core Features
- `log_created` - Created a log entry (count only, no content)
- `log_edited` - Edited a log
- `student_added` - Added a student
- `subject_added` - Added a subject
- `work_sample_added` - Attached a photo (count only)

### Engagement
- `session_start` - App opened
- `session_end` - App closed (with duration)
- `screen_view` - Which screens are visited
- `export_generated` - Created PDF/CSV export

### Errors
- `app_crash` - Crash with stack trace (no user data)
- `api_error` - API failures (for sync users)
- `sync_failed` - Sync errors

---

## Data Retention

- **Raw events**: 90 days
- **Aggregated stats**: Indefinitely
- **Crash reports**: 30 days

---

## Privacy Policy Updates

Add to privacy policy:

> **Analytics Data**
> 
> We collect anonymous usage statistics to improve the app. This includes:
> - A random identifier for your device (not linked to your identity)
> - App version and platform
> - Feature usage counts (not content)
> - Crash reports
> 
> This data cannot identify you or your family. You can disable analytics in Settings.
> 
> We do NOT collect:
> - Names, emails, or personal information
> - Content of your log entries
> - Information about your students
> - Location data

---

## Dashboard Metrics (Admin Portal)

Add to super admin portal:

### App Health
- Daily/Weekly/Monthly active installs
- App version distribution
- Platform breakdown (iOS/Android/Windows)
- Crash rate by version

### Engagement
- Onboarding completion rate
- Logs per session average
- Feature adoption (work samples, export)
- Sync conversion rate

### Retention
- Day 1, Day 7, Day 30 retention
- Churned installs (inactive 30+ days)

---

## Implementation Phases

### Phase 1: Basic Tracking
- [ ] Install ID generation
- [ ] Basic event schema
- [ ] Self-hosted endpoint `/api/v1/telemetry`
- [ ] Track: installs, sessions, crashes

### Phase 2: Feature Tracking
- [ ] Screen view tracking
- [ ] Feature usage events
- [ ] Onboarding funnel
- [ ] Admin dashboard charts

### Phase 3: Advanced
- [ ] Cohort analysis
- [ ] A/B testing support
- [ ] User feedback integration
- [ ] Crash reporting (Sentry?)

---

## Questions to Decide

1. **Opt-in or opt-out?**
   - Recommendation: Opt-out (default on, can disable)
   - More data, still privacy-respecting

Opt-out by default (which means enabled at first), but include that on the on-boarding screen and in settings

2. **Third-party or self-hosted?**
   - Recommendation: Self-hosted for now (simple endpoint)
   - Can add PostHog later for advanced analytics

Completely self hosted, no third party add a telemetry collection in the db

3. **How much to track?**
   - Recommendation: Start minimal (Tier 1 only)
   - Add Tier 2 once system is stable

I feel comportable with tier 1 and tier 2 as long as no PII is collected and this is disconnected from user accounts

4. **Track errors in detail?**
   - Recommendation: Yes, crashes are critical
   - Use Firebase Crashlytics or Sentry (privacy-reviewed)

Lets not worry about errors, because we can gather some crash from android/iOS stores

---

## Example: Minimal V1 Implementation

### Backend Endpoint

```go
// POST /api/v1/telemetry (no auth required)
type TelemetryEvent struct {
    InstallID   string                 `json:"installId"`
    AppVersion  string                 `json:"appVersion"`
    Platform    string                 `json:"platform"`
    Event       string                 `json:"event"`
    Data        map[string]interface{} `json:"data,omitempty"`
    Timestamp   time.Time              `json:"timestamp"`
}

// Rate limit: 100 events per install per day
// Store in separate collection: telemetry_events
```

### Mobile Client

```dart
class TelemetryService {
  bool _enabled = true; // Check settings
  
  Future<void> trackEvent(String event, [Map<String, dynamic>? data]) async {
    if (!_enabled) return;
    
    final payload = {
      'installId': await _getInstallId(),
      'appVersion': _appVersion,
      'platform': Platform.operatingSystem,
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    
    // Fire and forget - don't block UI
    _sendEvent(payload);
  }
}
```

---

*Last Updated: December 12, 2025*
