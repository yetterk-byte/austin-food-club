import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';

const AuthExample = () => {
  const { 
    user, 
    loading, 
    error, 
    signInWithPhone, 
    verifyOTP, 
    signOut, 
    clearError 
  } = useAuth();
  
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState('phone'); // 'phone' or 'otp'

  const handlePhoneSubmit = async (e) => {
    e.preventDefault();
    const result = await signInWithPhone(phone);
    if (result.success) {
      setStep('otp');
    }
  };

  const handleOTPSubmit = async (e) => {
    e.preventDefault();
    const result = await verifyOTP(phone, otp);
    if (result.success) {
      setStep('success');
    }
  };

  const handleSignOut = async () => {
    await signOut();
    setStep('phone');
    setPhone('');
    setOtp('');
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  if (user) {
    return (
      <div style={{ padding: '20px', color: 'white' }}>
        <h2>Welcome, {user.phone || user.email}!</h2>
        <p>User ID: {user.id}</p>
        <button onClick={handleSignOut}>Sign Out</button>
      </div>
    );
  }

  return (
    <div style={{ padding: '20px', color: 'white' }}>
      <h2>Authentication Example</h2>
      
      {error && (
        <div style={{ color: 'red', marginBottom: '10px' }}>
          {error}
          <button onClick={clearError} style={{ marginLeft: '10px' }}>Clear</button>
        </div>
      )}

      {step === 'phone' && (
        <form onSubmit={handlePhoneSubmit}>
          <div>
            <label>Phone Number:</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+1234567890"
              required
              style={{ width: '100%', padding: '8px', marginTop: '5px' }}
            />
          </div>
          <button type="submit" disabled={loading}>
            Send OTP
          </button>
        </form>
      )}

      {step === 'otp' && (
        <form onSubmit={handleOTPSubmit}>
          <div>
            <label>OTP Code:</label>
            <input
              type="text"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="123456"
              required
              style={{ width: '100%', padding: '8px', marginTop: '5px' }}
            />
          </div>
          <button type="submit" disabled={loading}>
            Verify OTP
          </button>
          <button type="button" onClick={() => setStep('phone')} style={{ marginLeft: '10px' }}>
            Back
          </button>
        </form>
      )}

      {step === 'success' && (
        <div style={{ color: 'green' }}>
          <p>Authentication successful! You should be redirected to the main app.</p>
        </div>
      )}
    </div>
  );
};

export default AuthExample;
