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

## 📝 Additional Notes

*Any other context, preferences, or requirements I should know:*

I've never made an app this wide scale before and a lot of it is out of my scope/whellhouse, so I want to make sure we do this right. I'm excited about this project and want to make it a great tool for homeschooling families. Let's keep communication open and iterate as needed to make sure we're aligned on goals and implementation.


---

*Please fill in your answers and save this file. I'll use your responses to make implementation decisions.*
