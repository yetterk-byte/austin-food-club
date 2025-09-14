import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import './PhoneAuth.css';

const PhoneAuth = () => {
  const { signInWithPhone, verifyOTP, loading, error, clearError } = useAuth();
  
  const [step, setStep] = useState('phone'); // 'phone' or 'otp'
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [formattedPhone, setFormattedPhone] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const [resendAttempts, setResendAttempts] = useState(0);

  // Format phone number as user types: (xxx) xxx-xxxx
  const formatPhoneNumber = (value) => {
    // Remove all non-digits
    const phoneNumber = value.replace(/\D/g, '');
    
    // Limit to 10 digits
    const limitedPhone = phoneNumber.slice(0, 10);
    
    // Format based on length
    if (limitedPhone.length === 0) return '';
    if (limitedPhone.length <= 3) return `(${limitedPhone}`;
    if (limitedPhone.length <= 6) return `(${limitedPhone.slice(0, 3)}) ${limitedPhone.slice(3)}`;
    return `(${limitedPhone.slice(0, 3)}) ${limitedPhone.slice(3, 6)}-${limitedPhone.slice(6)}`;
  };

  // Handle phone number input
  const handlePhoneChange = (e) => {
    const value = e.target.value;
    const formatted = formatPhoneNumber(value);
    setPhone(value.replace(/\D/g, '')); // Store only digits
    setFormattedPhone(formatted);
  };

  // Handle OTP input (only allow digits, max 6)
  const handleOtpChange = (e) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, 6);
    setOtp(value);
  };

  // Send OTP
  const handleSendOTP = async (e) => {
    e.preventDefault();
    
    if (phone.length !== 10) {
      return;
    }

    setIsSubmitting(true);
    clearError();

    const fullPhoneNumber = `+1${phone}`;
    const result = await signInWithPhone(fullPhoneNumber);

    if (result.success) {
      setStep('otp');
      setCountdown(60); // 60 second countdown
      setResendAttempts(prev => prev + 1);
    }
    
    setIsSubmitting(false);
  };

  // Verify OTP
  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    
    if (otp.length !== 6) {
      return;
    }

    setIsSubmitting(true);
    clearError();

    const fullPhoneNumber = `+1${phone}`;
    const result = await verifyOTP(fullPhoneNumber, otp);

    if (result.success) {
      // Success - user will be redirected by AuthContext
      console.log('Phone verification successful!');
    }
    
    setIsSubmitting(false);
  };

  // Resend OTP
  const handleResendOTP = async () => {
    if (countdown > 0 || resendAttempts >= 3) return;

    setIsSubmitting(true);
    clearError();

    const fullPhoneNumber = `+1${phone}`;
    const result = await signInWithPhone(fullPhoneNumber);

    if (result.success) {
      setCountdown(60);
      setResendAttempts(prev => prev + 1);
    }
    
    setIsSubmitting(false);
  };

  // Back to phone step
  const handleBackToPhone = () => {
    setStep('phone');
    setOtp('');
    clearError();
  };

  // Countdown timer
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  // Clear error when component mounts or step changes
  useEffect(() => {
    clearError();
  }, [step, clearError]);

  return (
    <div className="phone-auth-container">
      <div className="phone-auth-card">
        <div className="phone-auth-header">
          <h2>Welcome to Austin Food Club</h2>
          <p>Enter your phone number to get started</p>
        </div>

        {error && (
          <div className="error-message">
            <span>{error}</span>
            <button onClick={clearError} className="clear-error-btn">×</button>
          </div>
        )}

        {step === 'phone' && (
          <form onSubmit={handleSendOTP} className="phone-form">
            <div className="input-group">
              <label htmlFor="phone">Phone Number</label>
              <div className="phone-input-container">
                <span className="country-code">+1</span>
                <input
                  id="phone"
                  type="tel"
                  value={formattedPhone}
                  onChange={handlePhoneChange}
                  placeholder="(555) 123-4567"
                  className="phone-input"
                  maxLength={14} // (xxx) xxx-xxxx = 14 chars
                  disabled={isSubmitting}
                />
              </div>
              {phone.length > 0 && phone.length < 10 && (
                <span className="input-hint">Please enter a complete phone number</span>
              )}
            </div>

            <button
              type="submit"
              className="submit-btn"
              disabled={phone.length !== 10 || isSubmitting}
            >
              {isSubmitting ? 'Sending...' : 'Send Code'}
            </button>
          </form>
        )}

        {step === 'otp' && (
          <form onSubmit={handleVerifyOTP} className="otp-form">
            <div className="otp-header">
              <h3>Enter Verification Code</h3>
              <p>We sent a 6-digit code to +1{phone}</p>
            </div>

            <div className="input-group">
              <label htmlFor="otp">Verification Code</label>
              <input
                id="otp"
                type="text"
                value={otp}
                onChange={handleOtpChange}
                placeholder="123456"
                className="otp-input"
                maxLength={6}
                disabled={isSubmitting}
                autoComplete="one-time-code"
              />
              {otp.length > 0 && otp.length < 6 && (
                <span className="input-hint">Please enter all 6 digits</span>
              )}
            </div>

            <div className="otp-actions">
              <button
                type="submit"
                className="submit-btn"
                disabled={otp.length !== 6 || isSubmitting}
              >
                {isSubmitting ? 'Verifying...' : 'Verify Code'}
              </button>

              <div className="resend-section">
                {countdown > 0 ? (
                  <span className="countdown">
                    Resend code in {countdown}s
                  </span>
                ) : (
                  <button
                    type="button"
                    onClick={handleResendOTP}
                    className="resend-btn"
                    disabled={isSubmitting || resendAttempts >= 3}
                  >
                    {resendAttempts >= 3 ? 'Max attempts reached' : 'Resend Code'}
                  </button>
                )}
              </div>

              <button
                type="button"
                onClick={handleBackToPhone}
                className="back-btn"
                disabled={isSubmitting}
              >
                ← Change Phone Number
              </button>
            </div>
          </form>
        )}

        <div className="phone-auth-footer">
          <p>
            By continuing, you agree to our Terms of Service and Privacy Policy
          </p>
        </div>
      </div>
    </div>
  );
};

export default PhoneAuth;
