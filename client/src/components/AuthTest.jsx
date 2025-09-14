import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import './AuthTest.css';

const AuthTest = () => {
  const { 
    user, 
    loading, 
    error, 
    signInWithPhone, 
    verifyOTP, 
    signOut, 
    getCurrentUser,
    clearError 
  } = useAuth();
  
  const [phone, setPhone] = useState('+1234567890');
  const [otp, setOtp] = useState('');
  const [testResults, setTestResults] = useState([]);

  const addTestResult = (action, result, isError = false) => {
    const timestamp = new Date().toLocaleTimeString();
    const newResult = {
      id: Date.now(),
      timestamp,
      action,
      result: isError ? `ERROR: ${result}` : result,
      isError
    };
    setTestResults(prev => [newResult, ...prev].slice(0, 10)); // Keep last 10 results
  };

  const handleSendOTP = async () => {
    try {
      console.log('🔐 Testing: Send OTP to', phone);
      addTestResult('Send OTP', `Sending OTP to ${phone}...`);
      
      const result = await signInWithPhone(phone);
      
      console.log('📱 Send OTP Result:', result);
      addTestResult('Send OTP', `Success: ${JSON.stringify(result, null, 2)}`);
      
      if (result.success) {
        addTestResult('Send OTP', '✅ OTP sent successfully!');
      } else {
        addTestResult('Send OTP', `❌ Failed: ${result.error}`, true);
      }
    } catch (err) {
      console.error('❌ Send OTP Error:', err);
      addTestResult('Send OTP', `Exception: ${err.message}`, true);
    }
  };

  const handleVerifyOTP = async () => {
    try {
      console.log('🔑 Testing: Verify OTP', otp);
      addTestResult('Verify OTP', `Verifying OTP: ${otp}...`);
      
      const result = await verifyOTP(phone, otp);
      
      console.log('✅ Verify OTP Result:', result);
      addTestResult('Verify OTP', `Success: ${JSON.stringify(result, null, 2)}`);
      
      if (result.success) {
        addTestResult('Verify OTP', '✅ OTP verified successfully!');
      } else {
        addTestResult('Verify OTP', `❌ Failed: ${result.error}`, true);
      }
    } catch (err) {
      console.error('❌ Verify OTP Error:', err);
      addTestResult('Verify OTP', `Exception: ${err.message}`, true);
    }
  };

  const handleGetCurrentUser = async () => {
    try {
      console.log('👤 Testing: Get Current User');
      addTestResult('Get Current User', 'Fetching current user...');
      
      const result = await getCurrentUser();
      
      console.log('👤 Get Current User Result:', result);
      addTestResult('Get Current User', `Success: ${JSON.stringify(result, null, 2)}`);
      
      if (result.success) {
        addTestResult('Get Current User', `✅ User: ${result.user?.email || result.user?.phone || 'Unknown'}`);
      } else {
        addTestResult('Get Current User', `❌ Failed: ${result.error}`, true);
      }
    } catch (err) {
      console.error('❌ Get Current User Error:', err);
      addTestResult('Get Current User', `Exception: ${err.message}`, true);
    }
  };

  const handleSignOut = async () => {
    try {
      console.log('🚪 Testing: Sign Out');
      addTestResult('Sign Out', 'Signing out...');
      
      const result = await signOut();
      
      console.log('🚪 Sign Out Result:', result);
      addTestResult('Sign Out', `Success: ${JSON.stringify(result, null, 2)}`);
      
      if (result.success) {
        addTestResult('Sign Out', '✅ Signed out successfully!');
      } else {
        addTestResult('Sign Out', `❌ Failed: ${result.error}`, true);
      }
    } catch (err) {
      console.error('❌ Sign Out Error:', err);
      addTestResult('Sign Out', `Exception: ${err.message}`, true);
    }
  };

  const clearResults = () => {
    setTestResults([]);
  };

  return (
    <div className="auth-test-container">
      <div className="auth-test-header">
        <h2>🔐 Authentication Test Panel</h2>
        <p>Test Supabase authentication functionality</p>
      </div>

      {/* Current State */}
      <div className="auth-state">
        <h3>Current State</h3>
        <div className="state-info">
          <p><strong>User:</strong> {user ? `${user.email || user.phone || 'Authenticated'}` : 'Not authenticated'}</p>
          <p><strong>Loading:</strong> {loading ? 'Yes' : 'No'}</p>
          <p><strong>Error:</strong> {error || 'None'}</p>
        </div>
        {error && (
          <button onClick={clearError} className="clear-error-btn">
            Clear Error
          </button>
        )}
      </div>

      {/* Test Controls */}
      <div className="test-controls">
        <h3>Test Controls</h3>
        
        <div className="test-group">
          <h4>📱 Phone Authentication</h4>
          <div className="input-group">
            <label>Phone Number:</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+1234567890"
              className="phone-input"
            />
          </div>
          <button 
            onClick={handleSendOTP} 
            disabled={loading}
            className="test-btn primary"
          >
            {loading ? 'Sending...' : 'Send OTP'}
          </button>
        </div>

        <div className="test-group">
          <h4>🔑 OTP Verification</h4>
          <div className="input-group">
            <label>OTP Code:</label>
            <input
              type="text"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="123456"
              className="otp-input"
              maxLength={6}
            />
          </div>
          <button 
            onClick={handleVerifyOTP} 
            disabled={loading || !otp}
            className="test-btn primary"
          >
            {loading ? 'Verifying...' : 'Verify OTP'}
          </button>
        </div>

        <div className="test-group">
          <h4>👤 User Management</h4>
          <div className="button-row">
            <button 
              onClick={handleGetCurrentUser} 
              disabled={loading}
              className="test-btn secondary"
            >
              Get Current User
            </button>
            <button 
              onClick={handleSignOut} 
              disabled={loading || !user}
              className="test-btn danger"
            >
              Sign Out
            </button>
          </div>
        </div>
      </div>

      {/* Test Results */}
      <div className="test-results">
        <div className="results-header">
          <h3>Test Results</h3>
          <button onClick={clearResults} className="clear-results-btn">
            Clear Results
          </button>
        </div>
        
        <div className="results-list">
          {testResults.length === 0 ? (
            <p className="no-results">No test results yet. Run some tests above!</p>
          ) : (
            testResults.map(result => (
              <div 
                key={result.id} 
                className={`result-item ${result.isError ? 'error' : 'success'}`}
              >
                <div className="result-header">
                  <span className="result-action">{result.action}</span>
                  <span className="result-timestamp">{result.timestamp}</span>
                </div>
                <div className="result-content">
                  <pre>{result.result}</pre>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default AuthTest;
