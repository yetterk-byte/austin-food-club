import React, { useState, useEffect } from 'react';
import pushManager from '../services/pushManager';
import './NotificationSettings.css';

const NotificationSettings = () => {
  const [pushEnabled, setPushEnabled] = useState(false);
  const [preferences, setPreferences] = useState({
    weeklyAnnouncement: true,
    rsvpReminders: true,
    friendActivity: true,
    visitReminders: true,
    adminAlerts: false,
    quietHoursStart: "22:00",
    quietHoursEnd: "08:00",
    reminderHoursBefore: 2
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);

  useEffect(() => {
    loadPreferences();
    checkPushStatus();
  }, []);

  const loadPreferences = async () => {
    try {
      const prefs = await pushManager.getPreferences();
      setPreferences(prefs);
      setPushEnabled(prefs.pushEnabled);
    } catch (error) {
      console.error('Failed to load preferences:', error);
    } finally {
      setLoading(false);
    }
  };

  const checkPushStatus = async () => {
    const isSubscribed = await pushManager.checkSubscription();
    const permission = pushManager.getPermissionStatus();
    setPushEnabled(isSubscribed && permission === 'granted');
  };

  const enablePushNotifications = async () => {
    try {
      setLoading(true);
      
      if (!pushManager.isSupported()) {
        alert('Push notifications are not supported in this browser');
        return;
      }

      await pushManager.subscribeUser();
      
      // Update preferences to enable push
      const updatedPrefs = { ...preferences, pushEnabled: true };
      await pushManager.updatePreferences(updatedPrefs);
      
      setPreferences(updatedPrefs);
      setPushEnabled(true);
      
      // Show success message
      pushManager.showLocalNotification(
        '🎉 Notifications Enabled!',
        'You\'ll now receive updates from Austin Food Club'
      );
      
    } catch (error) {
      console.error('Failed to enable notifications:', error);
      alert('Failed to enable push notifications: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const disablePushNotifications = async () => {
    try {
      setLoading(true);
      
      await pushManager.unsubscribeUser();
      
      // Update preferences to disable push
      const updatedPrefs = { ...preferences, pushEnabled: false };
      await pushManager.updatePreferences(updatedPrefs);
      
      setPreferences(updatedPrefs);
      setPushEnabled(false);
      
    } catch (error) {
      console.error('Failed to disable notifications:', error);
      alert('Failed to disable push notifications: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const updatePreference = async (key, value) => {
    try {
      setSaving(true);
      
      const updatedPrefs = { ...preferences, [key]: value };
      await pushManager.updatePreferences(updatedPrefs);
      
      setPreferences(updatedPrefs);
    } catch (error) {
      console.error('Failed to update preference:', error);
      alert('Failed to update preference: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const sendTestNotification = async () => {
    try {
      setTesting(true);
      await pushManager.sendTestNotification();
      alert('Test notification sent! Check your notifications.');
    } catch (error) {
      console.error('Failed to send test notification:', error);
      alert('Failed to send test notification: ' + error.message);
    } finally {
      setTesting(false);
    }
  };

  if (loading) {
    return (
      <div className="notification-settings loading">
        <div className="loading-spinner"></div>
        <p>Loading notification settings...</p>
      </div>
    );
  }

  return (
    <div className="notification-settings">
      <div className="settings-header">
        <h2>🔔 Push Notifications</h2>
        <p>Stay updated with Austin Food Club</p>
      </div>

      {/* Push Status */}
      <div className="push-status-section">
        <div className={`push-status ${pushEnabled ? 'enabled' : 'disabled'}`}>
          {pushEnabled ? (
            <div className="status-enabled">
              <div className="status-icon">✅</div>
              <div className="status-content">
                <h3>Push notifications are enabled</h3>
                <p>You'll receive updates about restaurants, RSVPs, and friends</p>
                <button 
                  className="btn-secondary" 
                  onClick={disablePushNotifications}
                  disabled={loading}
                >
                  Disable Notifications
                </button>
                <button 
                  className="btn-test" 
                  onClick={sendTestNotification}
                  disabled={testing}
                >
                  {testing ? 'Sending...' : 'Send Test'}
                </button>
              </div>
            </div>
          ) : (
            <div className="status-disabled">
              <div className="status-icon">🔕</div>
              <div className="status-content">
                <h3>Get instant updates</h3>
                <div className="benefits">
                  <div className="benefit">📍 New weekly restaurant announcements</div>
                  <div className="benefit">⏰ Reminders for your RSVPs</div>
                  <div className="benefit">👥 When friends are going</div>
                  <div className="benefit">📸 Reminders to verify visits</div>
                </div>
                <button 
                  className="btn-primary enable-btn" 
                  onClick={enablePushNotifications}
                  disabled={loading}
                >
                  {loading ? 'Enabling...' : 'Enable Push Notifications'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Notification Types */}
      {pushEnabled && (
        <div className="notification-types-section">
          <h3>📱 Notification Types</h3>
          <div className="notification-types">
            <div className="notification-type">
              <label className="toggle-label">
                <input
                  type="checkbox"
                  checked={preferences.weeklyAnnouncement}
                  onChange={(e) => updatePreference('weeklyAnnouncement', e.target.checked)}
                  disabled={saving}
                />
                <span className="toggle-slider"></span>
                <div className="toggle-content">
                  <div className="toggle-title">🍽️ Weekly Restaurant Announcements</div>
                  <div className="toggle-description">Get notified when a new restaurant is featured</div>
                </div>
              </label>
            </div>

            <div className="notification-type">
              <label className="toggle-label">
                <input
                  type="checkbox"
                  checked={preferences.rsvpReminders}
                  onChange={(e) => updatePreference('rsvpReminders', e.target.checked)}
                  disabled={saving}
                />
                <span className="toggle-slider"></span>
                <div className="toggle-content">
                  <div className="toggle-title">⏰ RSVP Reminders</div>
                  <div className="toggle-description">Reminders before your restaurant visits</div>
                </div>
              </label>
            </div>

            <div className="notification-type">
              <label className="toggle-label">
                <input
                  type="checkbox"
                  checked={preferences.friendActivity}
                  onChange={(e) => updatePreference('friendActivity', e.target.checked)}
                  disabled={saving}
                />
                <span className="toggle-slider"></span>
                <div className="toggle-content">
                  <div className="toggle-title">👥 Friend Activity</div>
                  <div className="toggle-description">When friends RSVP or verify visits</div>
                </div>
              </label>
            </div>

            <div className="notification-type">
              <label className="toggle-label">
                <input
                  type="checkbox"
                  checked={preferences.visitReminders}
                  onChange={(e) => updatePreference('visitReminders', e.target.checked)}
                  disabled={saving}
                />
                <span className="toggle-slider"></span>
                <div className="toggle-content">
                  <div className="toggle-title">📸 Visit Reminders</div>
                  <div className="toggle-description">Reminders to verify your restaurant visits</div>
                </div>
              </label>
            </div>
          </div>
        </div>
      )}

      {/* Quiet Hours */}
      {pushEnabled && (
        <div className="quiet-hours-section">
          <h3>🌙 Quiet Hours</h3>
          <p>No notifications will be sent during these hours</p>
          <div className="quiet-hours">
            <div className="time-input">
              <label>Start:</label>
              <input
                type="time"
                value={preferences.quietHoursStart}
                onChange={(e) => updatePreference('quietHoursStart', e.target.value)}
                disabled={saving}
              />
            </div>
            <div className="time-separator">to</div>
            <div className="time-input">
              <label>End:</label>
              <input
                type="time"
                value={preferences.quietHoursEnd}
                onChange={(e) => updatePreference('quietHoursEnd', e.target.value)}
                disabled={saving}
              />
            </div>
          </div>
        </div>
      )}

      {/* Reminder Timing */}
      {pushEnabled && preferences.rsvpReminders && (
        <div className="reminder-timing-section">
          <h3>⏰ Reminder Timing</h3>
          <div className="reminder-timing">
            <label>Send RSVP reminders:</label>
            <select
              value={preferences.reminderHoursBefore}
              onChange={(e) => updatePreference('reminderHoursBefore', parseInt(e.target.value))}
              disabled={saving}
            >
              <option value={1}>1 hour before</option>
              <option value={2}>2 hours before</option>
              <option value={4}>4 hours before</option>
              <option value={24}>1 day before</option>
            </select>
          </div>
        </div>
      )}

      {/* Browser Support Info */}
      {!pushManager.isSupported() && (
        <div className="browser-support-info">
          <div className="warning">
            ⚠️ Push notifications are not supported in this browser
          </div>
          <p>For the best experience, use Chrome, Firefox, Safari, or Edge</p>
        </div>
      )}

      {saving && (
        <div className="saving-indicator">
          <div className="loading-spinner small"></div>
          Saving preferences...
        </div>
      )}
    </div>
  );
};

export default NotificationSettings;
