# Compliance & Security Requirements

## Applicable Laws

### FERPA (Family Educational Rights & Privacy Act)
- Applies to: Educational records of students
- Requirements:
  - Parents control access to their children's records
  - Cannot share student data without consent
  - Must provide access to records upon request
  - Must maintain security of records

### COPPA (Children's Online Privacy Protection Act)
- Applies to: Children under 13
- Requirements:
  - **Verifiable parental consent** before collecting data
  - Clear privacy policy
  - Parents can review/delete child's data
  - Minimize data collection
  - Data retention limits

### CIPA (Children's Internet Protection Act)
- Primarily for schools receiving federal funding
- Lower priority for our use case

---

## Security Implementation

### Authentication
- Strong password requirements (12+ chars, complexity)
- Optional 2FA (TOTP)
- Session management with JWT + refresh tokens
- Auto-logout after inactivity
- Device management (view/revoke sessions)

### Data Encryption
| Data State | Method |
|------------|--------|
| In Transit | TLS 1.3 |
| At Rest (Server) | AES-256 |
| At Rest (Device) | SQLCipher or encrypted storage |
| Backups | Encrypted before storage |
| File Attachments | Encrypted with per-file keys |

### Access Control
- Parents: Full access to their organization
- Students: View/submit only their own data
- No cross-organization data access
- Audit logging for all data access

### Data Minimization
- Collect only what's necessary
- DOB only for COPPA compliance
- No tracking/analytics beyond essential
- No third-party data sharing

---

## COPPA Workflow

```
Student Account Creation (under 13):
1. Parent creates student profile
2. Parent enables student login
3. System sends verification email to parent
4. Parent confirms consent via link
5. Student account activated
```

---

## Privacy Policy Requirements
- [ ] What data we collect
- [ ] How we use it
- [ ] How we protect it
- [ ] Parent rights (access, delete, modify)
- [ ] Data retention periods
- [ ] Contact information

---

## Incident Response
- Data breach notification within 72 hours
- Maintain incident log
- Regular security audits
- Penetration testing before launch
