# Payment & Subscription Research

**Status**: 🔬 Research Phase  
**Last Updated**: December 12, 2025

---

## TODO: Payment Implementation

This document tracks research and decisions around accepting payments for premium features.

---

## 📱 Platform Payment Requirements

### Apple App Store (iOS)

**Requirement**: Apple **requires** In-App Purchases (IAP) for digital goods/services consumed within the app.

| Scenario | Apple's Position |
|----------|------------------|
| Sync subscription | **Must use IAP** (30% cut, 15% after year 1) |
| Cloud storage | **Must use IAP** |
| Paid app download | Apple takes 30% of app price |
| Physical goods | Can use external payment |
| "Reader" apps (Netflix-style) | Can use external payment, but can't link to it in-app |

**Cross-platform subscriptions**: 
- If user pays on web, you CAN grant access on iOS
- BUT you cannot link to web payment from iOS app
- You must also offer IAP option in iOS app
- Apple's "anti-steering" rules have been loosened in some regions

**References**:
- [App Store Review Guidelines §3.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [StoreKit 2](https://developer.apple.com/storekit/)

---

### Google Play Store (Android)

**Requirement**: Google **requires** Play Billing for digital goods consumed in the app.

| Scenario | Google's Position |
|----------|-------------------|
| Sync subscription | **Must use Play Billing** (15-30% cut) |
| Cloud storage | **Must use Play Billing** |
| Paid app download | Google takes 15-30% of app price |
| Physical goods | Can use external payment |

**Cross-platform subscriptions**:
- If user pays on web, you CAN grant access on Android
- Google has been more lenient than Apple
- Must still offer Play Billing option in app

**References**:
- [Google Play Billing](https://developer.android.com/google/play/billing)
- [Play Console policies](https://support.google.com/googleplay/android-developer/answer/9858738)

---

## 💻 Web Payment Options

### Option 1: Stripe (Recommended)

**Pros**:
- Industry standard, excellent docs
- Easy subscription management
- Customer portal for self-service
- Handles taxes, invoices, receipts
- Webhook system for backend integration
- 2.9% + $0.30 per transaction (US)

**Cons**:
- Need to handle PCI compliance (Stripe.js makes this easy)
- Need backend integration

**Implementation**:
```
User clicks "Subscribe" → Stripe Checkout → Webhook confirms → Enable premium in DB
```

### Option 2: Paddle

**Pros**:
- Merchant of Record (they handle taxes, VAT, etc.)
- Works well for SaaS
- Simpler tax compliance
- 5% + $0.50 per transaction

**Cons**:
- Higher fees
- Less control over checkout experience

### Option 3: LemonSqueezy

**Pros**:
- Merchant of Record
- Good for indie developers
- Simple pricing: 5% + $0.50
- Nice UI out of the box

**Cons**:
- Newer, less mature
- Fewer integrations

---

## 🔄 Cross-Platform Subscription Sync

### The Challenge

User pays on web → How do they get access on mobile?

### Solution Architecture

```
                    ┌─────────────────┐
                    │   Web Payment   │
                    │  (Stripe/etc)   │
                    └────────┬────────┘
                             │ Webhook
                             ▼
                    ┌─────────────────┐
                    │    Backend      │
                    │ Family.Premium  │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
    ┌───────────┐     ┌───────────┐     ┌───────────┐
    │    Web    │     │    iOS    │     │  Android  │
    │   Check   │     │   Check   │     │   Check   │
    │  premium  │     │  premium  │     │  premium  │
    └───────────┘     └───────────┘     └───────────┘
```

### Implementation

1. **Web payment**: Stripe/Paddle webhook → Update `Family.Premium` in MongoDB
2. **Mobile apps**: On login/sync, fetch family data including `Premium` status
3. **IAP fallback**: Also offer IAP in mobile apps for users who prefer

### Handling IAP + Web

```go
// Backend tracks subscription source
type PremiumFeatures struct {
    SyncEnabled       bool
    UploadsEnabled    bool
    SubscriptionTier  string     // "free", "basic", "premium"
    SubscriptionSource string    // "web", "ios", "android"
    SubscriptionEnd   *time.Time
    // Store platform-specific IDs for verification
    StripeCustomerID  string
    AppleReceiptData  string  // For server-side receipt validation
    GooglePurchaseToken string
}
```

---

## 💰 Pricing Ideas

### Free Tier
- Unlimited local logging
- Local backup to device
- Basic export (CSV)
- No account required

### Basic Tier ($2.99/month or $24.99/year)
- Server sync across devices
- Account + family sharing
- PDF exports

### Premium Tier ($4.99/month or $39.99/year)
- Everything in Basic
- Work sample uploads (5GB storage)
- Priority support

---

## 📋 Implementation Checklist

### Phase 1: Web Payments
- [ ] Set up Stripe account
- [ ] Create products/prices in Stripe
- [ ] Implement checkout flow
- [ ] Handle webhooks (`checkout.session.completed`, `customer.subscription.updated`)
- [ ] Update `Family.Premium` on payment
- [ ] Customer portal for subscription management
- [ ] Cancellation handling

### Phase 2: Mobile IAP
- [ ] Set up products in App Store Connect
- [ ] Set up products in Google Play Console
- [ ] Implement RevenueCat or direct StoreKit/Play Billing
- [ ] Server-side receipt validation
- [ ] Sync IAP status to backend

### Phase 3: Cross-Platform Sync
- [ ] Ensure premium status syncs on login
- [ ] Handle subscription conflicts (paid on both platforms)
- [ ] Grace periods for expired subscriptions

---

## 🔗 Useful Resources

- [Stripe Subscriptions Guide](https://stripe.com/docs/billing/subscriptions/overview)
- [RevenueCat](https://www.revenuecat.com/) - Cross-platform IAP management
- [Apple StoreKit 2](https://developer.apple.com/documentation/storekit)
- [Google Play Billing Library](https://developer.android.com/google/play/billing)
- [Paddle Docs](https://developer.paddle.com/)

---

## ❓ Open Questions

1. Should we use RevenueCat to simplify cross-platform IAP?
   - Pros: Handles iOS/Android, analytics, server-side validation
   - Cons: Additional cost (1% of revenue after $2.5k/month)

2. How to handle free trial?
   - 7-day free trial for sync?
   - Or generous free tier?

3. Family sharing?
   - One subscription covers all users in a family?
   - Or per-user pricing?

4. Grandfather existing users?
   - If we launch free and add payments later, honor early adopters?

---

*This document will be updated as we research and implement payments.*
