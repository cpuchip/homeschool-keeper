# Homeschool Keeper - Questions & Ambiguities

**Purpose**: Questions I need your input on before implementing. Please fill in your answers and I'll incorporate them into the implementation.

---

## 🔐 Authentication

### Q1: Authentication Method for Web
ForKirk uses Google OAuth with cookie sessions. What auth method(s) do you want?

**Options**:
- [ ] A) Email/Password only (simpler, no third-party deps)
- [ ] B) Google OAuth only (like ForKirk)
- [x] C) Both Email/Password + Google OAuth
- [ ] D) Other: _______________

**Your Answer**: 

I want to start with Email/Password to begin with, and add Google OAuth in a later phase, since I don't want to deal with OAuth setup right away.

---

### Q2: Authentication for Mobile App
Mobile apps can't easily use cookie sessions. How should mobile authenticate?

**Options**:
- [x] A) JWT tokens (standard for mobile)
- [ ] B) Same cookie approach with secure storage
- [ ] C) OAuth with token refresh

**Your Answer**: 

we should use JWT tokens for mobile authentication, as it's the standard approach and works well with mobile apps, and it's what we use at work.

---

### Q3: Session Duration
How long should a user stay logged in before needing to re-authenticate?

**Options**:
- [ ] A) 7 days (week)
- [x] B) 30 days (month) - ForKirk uses this
- [ ] C) 90 days
- [ ] D) Until manual logout

**Your Answer**: 

I think 30 days is a good balance between user convenience and security, so let's go with that.

---

## 👨‍👩‍👧‍👦 User Roles & Permissions

### Q4: Initial Role Structure
What roles should exist at launch?

**Options**:
- [ ] A) Just "admin" (the parent who creates the account)
- [ ] B) "admin" and "parent" (for two-parent households)
- [x] C) "admin", "parent", and "student" (Phase 4 feature)
- [ ] D) Other: _______________

**Your Answer**: 

I really want to have that full structure from the start, so let's go with admin, parent/adult, and student roles.

---

### Q5: Multi-Family Support
Can one account/org have multiple families, or is it strictly 1 org = 1 family?

**Options**:
- [ ] A) 1 organization = 1 family (simple)
- [x] B) Support co-ops (multiple families in one org)

**Your Answer**: 

I think supporting co-ops is a great idea, so let's allow multiple families in one organization. But i want to keep families separate within the org, so they can break from the org if needed, and have their own students/logs. So I think logs should support being tied to a family within the org, and to the org itself. We should noodle on that more to decide how best to implement it.

Organizations can have multiple families, and the admins can manage which families are part of the org, and the admins could be parents in multiple families within the org. I think famlies could also be apart of different organizations too, so a parent could be in multiple orgs if needed.

---

## 📊 Hour Logging

### Q6: Hour Increment Default
What should the default hour increment be for new organizations?

**Options**:
- [x] A) 0.25 hours (15 minutes)
- [ ] B) 0.5 hours (30 minutes)
- [ ] C) 1.0 hour
- [ ] D) Let user choose during registration

**Your Answer**: 

This should be configurable per-organization later, but to start let's go with 0.25 hours as the default increment.

---

### Q7: Log Entry Status
Should parent-created logs require approval, or auto-approve?

**Options**:
- [x] A) Parent logs are auto-approved
- [ ] B) All logs start as "pending" regardless of creator
- [x] C) Configurable per-organization

**Your Answer**: 

Logs for each level are auto approved by default, but we can make this configurable per-organization/family later on.

for example if a student uses this app to log their own work in their own family it should be auto approved, there's no one else to approve it. Parents logs are auto approved for their own children. But if we have a co-op situation where multiple parents are involved maybe they want logs to be approved by another parent/admin before counting. So we can make this configurable later.

---

### Q8: Location Categories
What location options should be available for log entries?

**Current thinking**:
- `home` - At home instruction
- `field_trip` - Field trips
- `co_op` - Co-op classes
- `online` - Online courses
- `other` - Other

**Your additions/changes**: 

field_trip and other should have another field to specify the location name or details, like "Science Museum" or "Library". We should probably have a collection of locations per family/org that they can manage and select from when logging hours. We should also make it easy enough that they can add locations on the fly when logging if needed, like a quick "Add new location" option in the location dropdown and just start typing to add it, then worry about getting address or details later.

---

## 📚 Subjects

### Q9: Default Core Subjects
Missouri requires Reading, Math, Social Studies, Language Arts, and Science. Should I seed these automatically when a new org is created?

**Options**:
- [ ] A) Yes, auto-seed with Missouri defaults
- [ ] B) No, let user add their own
- [x] C) Ask user during onboarding which to include starting with missouri's defaults

**Your Answer**: 

In the end, I want onboarding to be state driven with defaults that can be customized. But to start let's just ask the user during onboarding which core subjects to include, and we can add state-driven defaults later.

---

### Q10: Subject Target Hours
Should each subject have a target hour goal, or just track totals?

**Options**:
- [ ] A) Yes, let users set target hours per subject
- [ ] B) No, just track state minimums (core vs elective totals)
- [x] C) Both (optional per-subject targets)

**Your Answer**: 

I'd like to let this be configurable per org/family. Some families may want to set target hours per subject, while others may just want to track totals. So let's allow both options.

---

## 📅 School Year

### Q11: School Year Dates
What should the default school year be?

**Options**:
- [ ] A) July 1 - June 30 (common homeschool year)
- [ ] B) August 1 - May 31 (traditional)
- [ ] C) September 1 - August 31
- [x] D) Fully configurable per organization

**Your Answer**: 

every area has different school year dates, so let's make this fully configurable per organization during onboarding.

---

### Q12: Multiple School Years
Should the app support viewing/managing multiple school years (current + past)?

**Options**:
- [x] A) Yes, full history with year switching
- [ ] B) Just current year for now (add history later)

**Your Answer**: 

I think allowing full history with year switching is important, so let's implement that from the start. But have a way for admins to mark a year as archived or read-only once it's over, so users don't accidentally modify past data.

---

## 🎨 UI/UX

### Q13: Theme
What color scheme/branding?

**Options**:
- [x] A) Blue/teal (educational feel)
- [ ] B) Green (growth/nature)
- [ ] C) Purple (creative)
- [ ] D) Custom colors: _______________

**Your Answer**: 

Just make it elegant and simple with a blue/teal educational feel. Nothing too flashy.

---

### Q14: App Name Display
How should the app be branded in the UI?

**Options**:
- [ ] A) "Homeschool Keeper"
- [ ] B) "HMS Logs" (matches domain hmslogs.com)
- [ ] C) "Homeschool Hours"
- [x] D) Other: _______________

**Your Answer**: 

Home School Logs is probably the best name for now, as it clearly describes the app's purpose.

---

## 🌐 Deployment

### Q15: Domain/Subdomain
What domain will this run on?

**Options**:
- [x] A) hmslogs.com (root)
- [ ] B) app.hmslogs.com (subdomain)
- [ ] C) Other: _______________

**Your Answer**: 

hmslogs.com root domain is good.

---

### Q16: MongoDB Database Name
What should the MongoDB database be named?

**Options**:
- [ ] A) `homeschool-keeper`
- [x] B) `hmslogs`
- [ ] C) Other: _______________

**Your Answer**: 

hmslogs is perfect.

---

## 📱 Mobile Priorities

### Q17: Mobile Platform Priority
Which mobile platform is higher priority?

**Options**:
- [ ] A) Android first
- [ ] B) iOS first
- [x] C) Both equally
- [ ] D) Web-only for now, mobile later

**Your Answer**: 

I don't have a macOS or iOS device at the moment but I want to keep that support, though for now we should have mac/iOS build support, but comment out the cicd for it until we have a mac to test on. so we don't waste github actions minutes building for iOS when we can't test it. but we should keep the code ready to go for when we can test it on a mac.

---

### Q18: Offline Support
How important is offline functionality for mobile?

**Options**:
- [x] A) Critical - must work fully offline
- [ ] B) Nice-to-have - basic offline, sync when online
- [ ] C) Not needed - require internet

**Your Answer**: 

The original plan was to have full offline support, but to start let's do basic offline with sync when online. We can build out full offline capabilities later once the core functionality is solid.

---

## 🔧 Technical Decisions

### Q19: Environment Variables
I'll need these values for production. Please provide or confirm:

| Variable | Value | Notes |
|----------|-------|-------|
| `MONGO_URI` | ??? | Production MongoDB connection string |
| `SESSION_SECRET` | ??? | Random 32+ character string |
| `PORT` | 8080 | Default, change if needed |
| `GOOGLE_CLIENT_ID` | ??? | Only if using Google OAuth |
| `GOOGLE_CLIENT_SECRET` | ??? | Only if using Google OAuth |

**Notes**: 

already have an .env file with most of these values set up for production, except the google oauth ones since we aren't using that yet.

---

### Q20: Email Notifications
Should the app send emails (password reset, reminders)?

**Options**:
- [x] A) Yes, set up email service (SendGrid, etc.)
- [ ] B) No emails for now

**Your Answer**: 

we'll need to research email services later, but for now let's plan to set up email notifications using a service like SendGrid when we implement password reset and other email features.

---

## 🚨 Priority Clarification

### Q21: Phase 1 Must-Haves
Rank these by importance (1 = most important):

| Feature | Priority (1-5) |
|---------|---------------|
| User login/register | 1 |
| Add/manage students | 1 |
| Add/manage subjects | 1 |
| Log hours (quick log) | 1|
| View hour statistics | 2|
| Dashboard overview | 2|
| Mobile app working | 3|

---

### Q22: Timeline Expectation
How quickly do you want Phase 1 functional?

**Options**:
- [ ] A) ASAP - minimal features, get it working
- [ ] B) 1-2 weeks - solid implementation
- [x] C) No rush - do it right

**Your Answer**: 

I have time to wait for a solid implementation, so no rush.

---

## ❓ Your Questions for Me

*Add any questions you have about the implementation here:*

1. How do we work with families and organizations for co-op support? especially if a family leaves an organization, how do we handle their data owned by the org? We should not delete it, so let them export it? clone it over to a new org? migrate it to their own family account or new family org? they wouldn't have access to it anymore from the old org, but we should give them options to take their data with them. What do you think is best? What do we do with that data that was in the org? I think that's why each log having a link to a student and a family is important, so we can keep that data tied to the family even if they leave the org. But we need to think through how to handle that in the UI and data model.
2. We need to have a a testing first approach here, everything should be solid: Unit tests, integration tests, e2e tests for both web and mobile. Do you have any preferences on testing frameworks or coverage requirements? I have wanted to learn and get into playwright for e2e testing for a while, so I think that would be a good fit for web e2e tests. For unit tests we can use the standard testing libraries for each platform (Go testing package, Vue Test Utils + Vitest, Flutter's test package). What do you think?
3. I'm worried about protecting user data and privacy, especially for minors. We should have a clear privacy policy and terms of service. Do you have any legal resources or templates we can use to draft these documents? Also, do you have any specific data protection measures you want to implement beyond standard security practices? We also cannot let data leak from one organization to another, or from one family to another. We need to make sure our data access layers are solid and well tested to prevent any accidental data leaks. We should also encrypt sensitive data at rest and in transit. What are your thoughts on this?
4. We need to have a solid plan about protecting data integrity, mongodb backups, s3 backups, offline sync may help with that too. Do you have any preferences or requirements for backup frequency, retention policies, or disaster recovery plans? When we have a first release lets focus on protecting user data as much as possible, but encrypted, see question 3 above.
5. I'm worried about the tangling of families and orgs and slowing down our first version, but I really want to make this app as flexible as possible. Do you think we should simplify the data model for phase 1 to just 1 org = 1 family, and then add co-op support later? Or do you want to tackle the more complex model from the start? I think we can do it from the start, but it may slow us down a bit. What do you think?

---

## 🤖 Follow-Up Questions (from Copilot)

### Q23: Family/Org Data Model Strategy
Based on your concerns about complexity, here's my recommendation. Please confirm:

**Proposed Approach - "Family First with Org Overlay"**:
1. **Family** is the core unit - every user belongs to a family, every student belongs to a family, every log belongs to a family
2. **Organization** is optional - families can join orgs for co-op features (shared subjects, group activities)
3. **Logs have dual ownership**: `familyId` (always) + `organizationId` (optional, for co-op logged activities)
4. **When family leaves org**: Their data stays with them (familyId is primary), org just loses access to see it

**Options**:
- [x] A) Yes, implement "Family First" from the start (more work upfront, but cleaner)
- [ ] B) Simplify Phase 1 to just `organizationId` = family, add proper families in Phase 2
- [ ] C) Different approach: _______________

**Your Answer**: 

I like the family first with org overlay approach.

---

### Q24: Data Ownership on Org Exit
When a family leaves an organization, what happens to:

**Logs created during co-op activities (e.g., "Math class at co-op")**:
- [ ] A) Family keeps a copy, org loses access entirely
- [x] B) Both keep a copy (fork the data)
- [ ] C) Family can choose: take copy or leave it with org
- [ ] D) Other: _______________

**Your Answer**: 

I'm thinking about this from a co-op perspective. if a co-op has two familes, A and B and family A's admin teaches math and logs it for students A.01 and B.01. we should have a parent log entry for the org that allows the org to see that log, but two individual log entries for each student tied to their family. So if family B leaves the org, they still have their own log entry for student B.01, but the org and family A still have their own log entry for student A.01. So both keep a copy of the log entry, but tied to their own family/org. We then would need to clone a record in family B such that the log of A's admin having taught math for log entry to B's student when they log it for the org is properly saved and editable by family B after they leave the org. I think it amounts to anything in the org that is tied to a families logs or students needs to be cloned (snapshotted) over to the family when they leave the org, but in an editable way so they can manage it on their own, and that wont be affected by any changes in the org after they leave.

Does that make sense? lets discuss more if needed.

---

### Q25: Testing Coverage Target
You mentioned testing-first. What's the minimum coverage bar before we consider code "done"?

**Options**:
- [ ] A) 80%+ coverage for core business logic (auth, logs, stats)
- [x] B) 60%+ overall, higher for critical paths
- [ ] C) No hard number, but every public function needs tests
- [ ] D) Other: _______________

**Your Answer**: 

I don't want to get over burdened with test coverage percentages, but I do want to make sure we have solid tests for all critical paths and business logic. So let's aim for 60%+ overall coverage, with a focus on critical paths like authentication, log management, and statistics calculations. We can always improve coverage over time as we add more features and refactor code. As well as when we have co-op features, we need to make sure those paths are well tested too. especially around log ownership and cloning when families leave orgs.

---

### Q26: Testing Stack Confirmation
Confirming your preferred testing stack:

| Layer | Tool | Confirm? |
|-------|------|----------|
| Go unit tests | Go `testing` package + `testify` | ✅ |
| Go integration tests | `testcontainers-go` for MongoDB | ✅ |
| Vue unit tests | Vitest + Vue Test Utils | ✅ |
| Vue E2E tests | Playwright | ✅ |
| Flutter unit tests | Flutter `test` package | ✅ |
| Flutter integration | Flutter integration_test | ✅ |
| API tests | Hurl or Bruno (REST client) | ✅ |

**Your changes/preferences**: 

all of those looks good, but I am really unfamiliar with hurl or bruno for api tests. I've dug into them a little and I think they seem fine. We should go with whichever one is easier to integrate into our ci/cd pipeline. Do you have a preference between the two? I assume one will let us write tests with a user logging in and getting a jwt token and using that for auth headers in later requests more easily than the other? If so let's go with that one.

---

### Q27: COPPA Compliance
Since students may be under 13, COPPA (Children's Online Privacy Protection Act) applies. How do you want to handle this?

**Options**:
- [ ] A) Require parental consent before any student account creation
- [ ] B) Students under 13 cannot have their own login (parent logs for them)
- [x] C) Full COPPA flow with verifiable parental consent
- [ ] D) Research this more before deciding

**Your Answer**: 

This will be a pain, but we should comply fully with the law. So let's implement a full COPPA flow with verifiable parental consent before allowing student account creation. We can research best practices and legal requirements to make sure we're doing this right.

---

### Q28: Encryption Scope
You mentioned encrypting sensitive data. What specifically should be encrypted at rest?

**Options** (check all that apply):
- [ ] Passwords (already planned - bcrypt hash)
- [ ] Student names
- [ ] Student date of birth
- [ ] Log descriptions/notes
- [x] File attachments (work samples)
- [x] All PII fields
- [x] Everything in the database

**Your Answer**: 

I think if we can encrypt everything in the database at rest that would be best. We should use AES-256 encryption for all data at rest, and ensure that our encryption keys are securely managed. We should also make sure that any sensitive data transmitted over the network is done so using HTTPS/TLS to protect it in transit.

---

### Q29: Backup Strategy
For MongoDB backups, what's your preference?

**Options**:
- [x] A) Daily backups, 30-day retention (standard)
- [x] B) Hourly backups for last 24h, then daily for 30 days
- [ ] C) Use MongoDB Atlas managed backups (if moving to Atlas)
- [ ] D) Self-managed with mongodump to S3

**Notes on current Dokploy setup**: 

I really don't know what the best stratagy here is, though dokploy does have some options. lets investigate that and add to it anything we need to feel comfortable here.

---

### Q30: Phase 1 Scope - Your Final Call
Given all we've discussed, here's my recommendation for Phase 1 scope. Please confirm or adjust:

**Phase 1A (MVP - Get it Working)**:
- [x] Email/password auth (web cookie sessions)
- [x] Single family model (org = family, keep schema ready for multi-family)
- [x] Students CRUD
- [x] Subjects CRUD (with Missouri defaults during onboarding)
- [x] Log entries CRUD (quick log)
- [x] Basic stats (total hours, core vs elective)
- [x] Dashboard with progress bars
- [ ] Mobile app (defer to Phase 1B)

**Phase 1B (Polish)**:
- [x] Mobile app with JWT auth
- [x] Proper family/org split
- [x] Location management
- [x] Multi-year support
- [ ] Basic offline sync (defer full offline to Phase 2)

**Your adjustments**:

---

### Q31: Copilot Instructions Scope
You mentioned wanting a .github / copilot-instructions. What should they cover?

**Suggested sections**:
- [x] Simple project structure overview (where to put code/docs)
- [x] Coding conventions (Go, Vue, Flutter)
- [x] App architecture overview (backend, frontend, mobile, deployment infrastructure)
- [x] Testing requirements
- [ ] Data model relationships
- [x] Security considerations
- [ ] API design patterns
- [ ] State compliance rules
- [ ] Other: _______________

**Your Answer**: 

---

### Q32: AGENTS.md Purpose
What do you want the AGENTS.md file to help with?

**Options**:
- [x] A) Agent prompts for specific development tasks (backend, frontend, mobile)
- [ ] B) Onboarding guide for new AI agents working on this codebase
- [x] C) System prompts for specialized agents (testing agent, security agent, etc.)
- [ ] D) All of the above
- [x] E) Other: _______________

**Your Answer**:

For other, I want an agent that will help with writing customer facing documentation, one that will help me research the various states homeschooling laws and requirements, and one that will help me with marketing copy and ideas for promoting the app once it's ready to launch.

---

## 📝 Additional Notes

*Any other context, preferences, or requirements I should know:*

I've never made an app this wide scale before and a lot of it is out of my scope/whellhouse, so I want to make sure we do this right. I'm excited about this project and want to make it a great tool for homeschooling families. Let's keep communication open and iterate as needed to make sure we're aligned on goals and implementation.


---

*Please fill in your answers and save this file. I'll use your responses to make implementation decisions.*
