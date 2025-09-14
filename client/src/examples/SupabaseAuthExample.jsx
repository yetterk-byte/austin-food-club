import React, { useState, useEffect } from 'react';
import { auth } from '../services/supabase';

const SupabaseAuthExample = () => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  // Check for existing user on component mount
  useEffect(() => {
    checkUser();
  }, []);

  const checkUser = async () => {
    const { data, error } = await auth.getCurrentUser();
    if (data) {
      setUser(data);
    }
  };

  const handlePhoneSignIn = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    const { data, error } = await auth.signInWithPhone(phone);
    
    if (error) {
      setMessage(`Error: ${error.message}`);
    } else {
      setMessage('OTP sent to your phone!');
    }
    
    setLoading(false);
  };

  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    const { data, error } = await auth.verifyOTP(phone, otp);
    
    if (error) {
      setMessage(`Error: ${error.message}`);
    } else {
      setUser(data.user);
      setMessage('Successfully signed in!');
    }
    
    setLoading(false);
  };

  const handleSignOut = async () => {
    setLoading(true);
    const { error } = await auth.signOut();
    
    if (error) {
      setMessage(`Error: ${error.message}`);
    } else {
      setUser(null);
      setMessage('Signed out successfully!');
    }
    
    setLoading(false);
  };

  if (user) {
    return (
      <div style={{ padding: '20px', maxWidth: '400px', margin: '0 auto' }}>
        <h2>Welcome, {user.email || user.phone}!</h2>
        <p>User ID: {user.id}</p>
        <button onClick={handleSignOut} disabled={loading}>
          {loading ? 'Signing out...' : 'Sign Out'}
        </button>
        {message && <p style={{ color: 'green' }}>{message}</p>}
      </div>
    );
  }

  return (
    <div style={{ padding: '20px', maxWidth: '400px', margin: '0 auto' }}>
      <h2>Phone Authentication</h2>
      
      <form onSubmit={handlePhoneSignIn}>
        <div style={{ marginBottom: '10px' }}>
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
          {loading ? 'Sending...' : 'Send OTP'}
        </button>
      </form>

      {message.includes('OTP sent') && (
        <form onSubmit={handleVerifyOTP} style={{ marginTop: '20px' }}>
          <div style={{ marginBottom: '10px' }}>
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
            {loading ? 'Verifying...' : 'Verify OTP'}
          </button>
        </form>
      )}

      {message && <p style={{ color: message.includes('Error') ? 'red' : 'green' }}>{message}</p>}
    </div>
  );
};

export default SupabaseAuthExample;
