const twilio = require('twilio');

class TwilioService {
  constructor() {
    this.accountSid = process.env.TWILIO_ACCOUNT_SID;
    this.authToken = process.env.TWILIO_AUTH_TOKEN;
    this.phoneNumber = process.env.TWILIO_PHONE_NUMBER;
    
    // Check if credentials are missing or are placeholder values
    const isPlaceholder = (value) => value && value.includes('your_') && value.includes('_here');
    
    if (!this.accountSid || !this.authToken || !this.phoneNumber || 
        isPlaceholder(this.accountSid) || isPlaceholder(this.authToken) || isPlaceholder(this.phoneNumber)) {
      console.warn('Twilio credentials not found. SMS functionality will be disabled.');
      this.client = null;
    } else {
      this.client = twilio(this.accountSid, this.authToken);
    }
  }

  /**
   * Send SMS message
   * @param {string} to - Recipient phone number (E.164 format)
   * @param {string} message - Message content
   * @returns {Promise<{success: boolean, sid?: string, error?: string}>}
   */
  async sendSMS(to, message) {
    if (!this.client) {
      return {
        success: false,
        error: 'Twilio not configured. Please set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER environment variables.'
      };
    }

    try {
      // Validate phone number format (basic E.164 check)
      if (!to.startsWith('+') || to.length < 10) {
        return {
          success: false,
          error: 'Invalid phone number format. Use E.164 format (e.g., +1234567890)'
        };
      }

      const result = await this.client.messages.create({
        body: message,
        from: this.phoneNumber,
        to: to
      });

      console.log(`SMS sent successfully. SID: ${result.sid}`);
      return {
        success: true,
        sid: result.sid
      };
    } catch (error) {
      console.error('Error sending SMS:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Send OTP verification code
   * @param {string} phoneNumber - Phone number to send OTP to
   * @param {string} customCode - Custom verification code (optional)
   * @returns {Promise<{success: boolean, error?: string}>}
   */
  async sendOTP(phoneNumber, customCode = null) {
    const otpCode = customCode || Math.floor(100000 + Math.random() * 900000).toString();
    const message = `Your Austin Food Club verification code is: ${otpCode}. This code expires in 10 minutes.`;
    
    const result = await this.sendSMS(phoneNumber, message);
    
    if (result.success) {
      console.log(`OTP sent to ${phoneNumber}: ${otpCode}`);
      return {
        success: true,
        otpCode: otpCode // Only for testing - remove in production
      };
    }
    
    return result;
  }

  /**
   * Check if Twilio is properly configured
   * @returns {boolean}
   */
  isConfigured() {
    return this.client !== null;
  }
}

module.exports = new TwilioService();
