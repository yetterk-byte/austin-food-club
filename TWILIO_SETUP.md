# Twilio Setup for Austin Food Club

This guide covers setting up Twilio for SMS authentication and notifications in the Austin Food Club application.

## Prerequisites

1. A Twilio account (sign up at [twilio.com](https://www.twilio.com))
2. A verified phone number for testing
3. Access to the Twilio Console

## 1. Setting Up Twilio Trial Account

### Step 1: Create Twilio Account
1. Go to [twilio.com](https://www.twilio.com) and sign up
2. Verify your email address
3. Complete the account verification process

### Step 2: Get Your Account Credentials
1. Log into the [Twilio Console](https://console.twilio.com)
2. Navigate to **Account** → **API Keys & Tokens**
3. Note down your:
   - **Account SID** (starts with `AC...`)
   - **Auth Token** (click "Show" to reveal)
   - **Phone Number** (from Phone Numbers → Manage → Active numbers)

### Step 3: Verify Phone Numbers for Testing

#### For Trial Accounts:
1. Go to **Phone Numbers** → **Manage** → **Verified Caller IDs**
2. Click **Add a new number**
3. Enter the phone number you want to verify
4. Choose verification method (SMS or Voice call)
5. Enter the verification code received
6. The number will now be added to your verified list

#### Important Trial Account Limitations:
- **SMS**: Can only send to verified phone numbers
- **Voice**: Can only call verified phone numbers
- **Rate Limits**: Limited to 1 SMS per second
- **Daily Limits**: Limited number of messages per day
- **Message Content**: Must include "Sent from your Twilio trial account" in messages

## 2. Team Test Phone Numbers

### Recommended Test Numbers for Development:

| Team Member | Phone Number | Purpose | Notes |
|-------------|--------------|---------|-------|
| **Primary Developer** | `+1 (555) 123-4567` | Main testing | Use your actual number |
| **Backend Developer** | `+1 (555) 234-5678` | API testing | Use your actual number |
| **Frontend Developer** | `+1 (555) 345-6789` | UI testing | Use your actual number |
| **QA Tester** | `+1 (555) 456-7890` | End-to-end testing | Use your actual number |
| **Product Manager** | `+1 (555) 567-8901` | Feature testing | Use your actual number |

### Adding Team Numbers:
1. Each team member should verify their own phone number
2. Add all verified numbers to the project documentation
3. Update the test numbers list as team members change

## 3. Environment Configuration

### Server Environment Variables
Add these to your `server/.env` file:

```env
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=your_twilio_phone_number_here

# Optional: For production
TWILIO_VERIFY_SERVICE_SID=your_verify_service_sid_here
```

### Client Environment Variables
Add these to your `client/.env` file:

```env
# Twilio Configuration (if needed on client)
REACT_APP_TWILIO_ACCOUNT_SID=your_account_sid_here
REACT_APP_TWILIO_VERIFY_SERVICE_SID=your_verify_service_sid_here
```

## 4. Twilio Services Setup

### SMS Service
The project uses Twilio for:
- **OTP Authentication**: Sending verification codes
- **Notifications**: RSVP reminders, event updates
- **Alerts**: System notifications

### Verify Service (Recommended)
For better OTP management, set up Twilio Verify:
1. Go to **Verify** → **Services** in Twilio Console
2. Click **Create new Service**
3. Name it "Austin Food Club Auth"
4. Note the **Service SID** for your environment variables

## 5. Testing Your Setup

### Test SMS Sending
```bash
# Test from server directory
curl -X POST http://localhost:3001/api/test/sms \
  -H "Content-Type: application/json" \
  -d '{"phone": "+1234567890", "message": "Test message"}'
```

### Test OTP Flow
1. Start the application
2. Navigate to the login page
3. Enter a verified phone number
4. Check for SMS delivery
5. Verify OTP code entry works

## 6. Production Considerations

### Upgrading from Trial
When ready for production:
1. **Upgrade Account**: Remove trial limitations
2. **Purchase Phone Number**: Get a dedicated number
3. **Set Up Webhooks**: Configure status callbacks
4. **Monitor Usage**: Set up billing alerts
5. **Rate Limiting**: Implement proper rate limiting

### Security Best Practices
- **Never commit credentials** to version control
- **Use environment variables** for all sensitive data
- **Rotate tokens** regularly
- **Monitor usage** for unusual activity
- **Implement rate limiting** on SMS endpoints

## 7. Troubleshooting

### Common Issues

#### "The number is unverified"
- **Solution**: Add the number to verified caller IDs
- **Check**: Trial account limitations

#### "Invalid phone number format"
- **Solution**: Use E.164 format (+1234567890)
- **Check**: Include country code

#### "Message delivery failed"
- **Solution**: Check phone number validity
- **Check**: Verify account has sufficient credits

#### "Rate limit exceeded"
- **Solution**: Implement exponential backoff
- **Check**: Trial account has 1 SMS/second limit

### Debug Mode
Enable debug logging in your Twilio service:

```javascript
// In your Twilio service configuration
const client = require('twilio')(accountSid, authToken, {
  logLevel: 'debug'
});
```

## 8. Support and Resources

- **Twilio Documentation**: [twilio.com/docs](https://www.twilio.com/docs)
- **SMS API Reference**: [twilio.com/docs/sms](https://www.twilio.com/docs/sms)
- **Verify API Reference**: [twilio.com/docs/verify](https://www.twilio.com/docs/verify)
- **Twilio Console**: [console.twilio.com](https://console.twilio.com)
- **Support**: Available through Twilio Console

## 9. Alternative: Magic Link Authentication

### Magic Link vs SMS OTP
Instead of SMS-based authentication, you can use **Magic Link** authentication which:
- ✅ **No phone verification needed** - works with any email
- ✅ **Better user experience** - just click a link in email
- ✅ **No SMS costs** - completely free
- ✅ **More reliable** - no carrier blocking issues
- ✅ **Works globally** - no country restrictions

### Magic Link Implementation
The project includes a `MagicLinkAuth.jsx` component that:
1. Takes user email address
2. Calls `supabase.auth.signInWithOtp({ email, options: { shouldCreateUser: true } })`
3. Shows "Check your email for login link" message
4. User clicks link in email to sign in automatically

### Usage Example
```jsx
import MagicLinkAuth from './components/MagicLinkAuth';

// In your component
<MagicLinkAuth 
  onSuccess={(data) => console.log('Magic link sent:', data)}
  onError={(error) => console.error('Error:', error)}
/>
```

## 10. Cost Management

### Trial Account
- **Free Credits**: $15-20 worth of usage
- **SMS Cost**: ~$0.0075 per message
- **Voice Cost**: ~$0.02 per minute

### Production Estimates
- **Monthly SMS**: ~$5-50 depending on usage
- **Phone Number**: ~$1/month
- **Verify Service**: ~$0.05 per verification
- **Magic Link**: **FREE** (no additional costs)

### Monitoring
- Set up billing alerts in Twilio Console
- Monitor usage through the dashboard
- Implement usage tracking in your application

---

**Note**: This setup is specifically for the Austin Food Club application. Update phone numbers and configurations as needed for your team.
