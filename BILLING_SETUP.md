# Firebase Billing Setup for Phone Authentication

## Issue: BILLING_NOT_ENABLED
Phone authentication requires a paid Firebase plan (Blaze) to work. The free Spark plan doesn't support phone authentication.

## Solution 1: Enable Billing (Recommended)

### Step 1: Upgrade to Blaze Plan
1. Go to [Firebase Console](https://console.firebase.google.com/project/farmagrotech-7d3a7)
2. Click the gear icon (⚙️) next to "Project Overview"
3. Select "Project settings"
4. Click on "Billing" tab
5. Click "Upgrade to Blaze plan"
6. Add a payment method (credit card)

### Step 2: Blaze Plan Benefits
- **Free Tier**: 10,000 phone authentications per month
- **Pay-as-you-go**: $0.01 per verification after free tier
- **No upfront costs**: Only pay for what you use
- **Most apps stay within free tier**

### Step 3: Set Quota Limits (Recommended)
1. Go to **Authentication** → **Sign-in method** → **Phone**
2. Set quota limits:
   - Daily quota: 100 verifications
   - Monthly quota: 1,000 verifications
3. This prevents unexpected charges

## Solution 2: Use Test Phone Numbers (Free)

### For Development Only
1. Go to **Authentication** → **Sign-in method** → **Phone**
2. Scroll down to "Test phone numbers"
3. Add test numbers:
   - Phone: `+1234567890`
   - Code: `123456`
4. Use these numbers in your app for testing

### Test Phone Numbers
```
Phone: +1234567890, Code: 123456
Phone: +1987654321, Code: 654321
Phone: +1555123456, Code: 111111
```

## Solution 3: Disable Phone Auth (Temporary)

### If you want to keep free plan
1. Go to **Authentication** → **Sign-in method**
2. Click on "Phone"
3. Toggle "Enable" to OFF
4. Use only email authentication for now
5. Enable phone auth later when ready to upgrade

## Cost Breakdown

### Blaze Plan Pricing
- **Phone Authentication**: $0.01 per verification
- **Free Tier**: 10,000 verifications/month
- **Typical App Usage**: 100-1,000 verifications/month
- **Monthly Cost**: $0-10 for most apps

### Example Costs
- 100 verifications/month: $0 (free tier)
- 1,000 verifications/month: $0 (free tier)
- 5,000 verifications/month: $0 (free tier)
- 15,000 verifications/month: $5 (5,000 × $0.01)

## Security Considerations

### App Check (Optional)
- **Purpose**: Prevents abuse and bot attacks
- **Cost**: Free for first 10,000 requests/month
- **Setup**: Project Settings → App Check
- **Recommendation**: Enable for production

### Quota Management
- **Set daily limits**: Prevent abuse
- **Monitor usage**: Check Firebase Console regularly
- **Alert thresholds**: Set up billing alerts

## Next Steps

1. **Choose a solution** based on your needs
2. **Enable billing** if you want full phone auth
3. **Set quota limits** to control costs
4. **Test thoroughly** before production
5. **Monitor usage** regularly

## Support
- **Firebase Support**: https://firebase.google.com/support
- **Billing Help**: https://firebase.google.com/support/billing
- **Phone Auth Docs**: https://firebase.google.com/docs/auth/android/phone-auth
