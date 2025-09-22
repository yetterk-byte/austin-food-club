/**
 * Push Notification Manager for Austin Food Club Web App
 * Handles web push subscription and notification management
 */

class PushManager {
  constructor() {
    this.vapidPublicKey = process.env.REACT_APP_VAPID_PUBLIC_KEY;
    this.apiBaseUrl = process.env.REACT_APP_API_URL || 'http://localhost:3001';
  }

  /**
   * Check if push notifications are supported
   */
  isSupported() {
    return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  }

  /**
   * Get current notification permission status
   */
  getPermissionStatus() {
    if (!this.isSupported()) {
      return 'unsupported';
    }
    return Notification.permission;
  }

  /**
   * Request notification permission
   */
  async requestPermission() {
    if (!this.isSupported()) {
      throw new Error('Push notifications are not supported in this browser');
    }

    const permission = await Notification.requestPermission();
    
    if (permission !== 'granted') {
      throw new Error(`Permission ${permission}: User denied notification permission`);
    }

    console.log('✅ Notification permission granted');
    return permission;
  }

  /**
   * Register service worker
   */
  async registerServiceWorker() {
    if (!('serviceWorker' in navigator)) {
      throw new Error('Service workers are not supported');
    }

    try {
      const registration = await navigator.serviceWorker.register('/service-worker.js', {
        scope: '/'
      });

      console.log('✅ Service Worker registered:', registration.scope);
      
      // Wait for service worker to be ready
      await navigator.serviceWorker.ready;
      
      return registration;
    } catch (error) {
      console.error('❌ Service Worker registration failed:', error);
      throw error;
    }
  }

  /**
   * Subscribe user to push notifications
   */
  async subscribeUser() {
    try {
      // Request permission first
      await this.requestPermission();

      // Register service worker
      const registration = await this.registerServiceWorker();

      // Check if already subscribed
      const existingSubscription = await registration.pushManager.getSubscription();
      if (existingSubscription) {
        console.log('📱 Existing subscription found');
        await this.sendSubscriptionToServer(existingSubscription);
        return existingSubscription;
      }

      // Create new subscription
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKey)
      });

      console.log('✅ New push subscription created');
      
      // Send subscription to server
      await this.sendSubscriptionToServer(subscription);

      return subscription;
    } catch (error) {
      console.error('❌ Error subscribing to push notifications:', error);
      throw error;
    }
  }

  /**
   * Unsubscribe from push notifications
   */
  async unsubscribeUser() {
    try {
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();

      if (subscription) {
        await subscription.unsubscribe();
        console.log('✅ Unsubscribed from push notifications');
        
        // Notify server
        await this.removeSubscriptionFromServer();
      }

      return true;
    } catch (error) {
      console.error('❌ Error unsubscribing:', error);
      throw error;
    }
  }

  /**
   * Check if user is currently subscribed
   */
  async checkSubscription() {
    try {
      if (!this.isSupported()) {
        return false;
      }

      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();
      
      return subscription !== null;
    } catch (error) {
      console.error('❌ Error checking subscription:', error);
      return false;
    }
  }

  /**
   * Send subscription to server
   */
  async sendSubscriptionToServer(subscription) {
    const deviceInfo = {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      timestamp: new Date().toISOString()
    };

    const response = await fetch(`${this.apiBaseUrl}/api/notifications/subscribe`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.getAuthToken()}`
      },
      body: JSON.stringify({
        subscription: subscription.toJSON(),
        platform: 'web',
        deviceInfo
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to save subscription');
    }

    const result = await response.json();
    console.log('✅ Subscription saved to server:', result);
    return result;
  }

  /**
   * Remove subscription from server
   */
  async removeSubscriptionFromServer() {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/notifications/unsubscribe`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`
        }
      });

      if (response.ok) {
        console.log('✅ Subscription removed from server');
      }
    } catch (error) {
      console.error('❌ Error removing subscription from server:', error);
    }
  }

  /**
   * Get notification preferences
   */
  async getPreferences() {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/notifications/preferences`, {
        headers: {
          'Authorization': `Bearer ${this.getAuthToken()}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to get preferences');
      }

      const result = await response.json();
      return result.preferences;
    } catch (error) {
      console.error('❌ Error getting preferences:', error);
      throw error;
    }
  }

  /**
   * Update notification preferences
   */
  async updatePreferences(preferences) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/notifications/preferences`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`
        },
        body: JSON.stringify(preferences)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to update preferences');
      }

      const result = await response.json();
      console.log('✅ Preferences updated:', result);
      return result.preferences;
    } catch (error) {
      console.error('❌ Error updating preferences:', error);
      throw error;
    }
  }

  /**
   * Send test notification
   */
  async sendTestNotification() {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/notifications/test`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`
        },
        body: JSON.stringify({ platform: 'web' })
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to send test notification');
      }

      const result = await response.json();
      console.log('✅ Test notification sent:', result);
      return result;
    } catch (error) {
      console.error('❌ Error sending test notification:', error);
      throw error;
    }
  }

  /**
   * Utility methods
   */
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  getAuthToken() {
    // Get token from localStorage or your auth system
    return localStorage.getItem('auth_token') || '';
  }

  /**
   * Show local notification (fallback)
   */
  showLocalNotification(title, body, options = {}) {
    if (this.getPermissionStatus() === 'granted') {
      new Notification(title, {
        body,
        icon: '/icon-192x192.png',
        ...options
      });
    }
  }
}

// Export singleton instance
const pushManager = new PushManager();
export default pushManager;
