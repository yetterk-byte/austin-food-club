const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateUserPreferences() {
  try {
    console.log('🔧 Updating user preferences...');
    
    // Update the demo user's preferences to enable push notifications
    const updated = await prisma.notificationPreferences.upsert({
      where: { userId: 'demo-user-123' },
      create: {
        userId: 'demo-user-123',
        pushEnabled: true,
        weeklyAnnouncement: true,
        rsvpReminders: true,
        friendActivity: true,
        visitReminders: true,
        adminAlerts: true,
        quietHoursStart: "22:00",
        quietHoursEnd: "08:00",
        reminderHoursBefore: 2
      },
      update: {
        pushEnabled: true,
        adminAlerts: true
      }
    });
    
    console.log('✅ User preferences updated:', updated);
    
    // Check subscription stats
    const stats = await prisma.pushSubscription.count({
      where: { isActive: true }
    });
    
    console.log(`📊 Active subscriptions: ${stats}`);
    
  } catch (error) {
    console.error('❌ Error updating preferences:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateUserPreferences();
