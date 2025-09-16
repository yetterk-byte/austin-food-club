const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function cleanupDuplicateRSVPs() {
  try {
    console.log('🧹 Starting cleanup of duplicate RSVPs...');
    
    // Find all users who have multiple RSVPs for the same restaurant
    const duplicateRSVPs = await prisma.rSVP.groupBy({
      by: ['userId', 'restaurantId'],
      having: {
        userId: {
          _count: {
            gt: 1
          }
        }
      },
      _count: {
        id: true
      }
    });

    console.log(`Found ${duplicateRSVPs.length} user-restaurant pairs with duplicate RSVPs`);

    let totalDeleted = 0;

    for (const duplicate of duplicateRSVPs) {
      console.log(`\nCleaning up duplicates for user ${duplicate.userId} and restaurant ${duplicate.restaurantId}`);
      
      // Get all RSVPs for this user-restaurant pair
      const rsvps = await prisma.rSVP.findMany({
        where: {
          userId: duplicate.userId,
          restaurantId: duplicate.restaurantId
        },
        orderBy: {
          createdAt: 'desc' // Keep the most recent one
        }
      });

      console.log(`  Found ${rsvps.length} RSVPs, keeping the most recent one`);

      // Keep the first (most recent) RSVP, delete the rest
      const toKeep = rsvps[0];
      const toDelete = rsvps.slice(1);

      console.log(`  Keeping RSVP: ${toKeep.day} - ${toKeep.status} (${toKeep.createdAt})`);

      for (const rsvp of toDelete) {
        console.log(`  Deleting RSVP: ${rsvp.day} - ${rsvp.status} (${rsvp.createdAt})`);
        await prisma.rSVP.delete({
          where: { id: rsvp.id }
        });
        totalDeleted++;
      }
    }

    console.log(`\n✅ Cleanup complete! Deleted ${totalDeleted} duplicate RSVPs`);
    
    // Verify the cleanup
    const remainingDuplicates = await prisma.rSVP.groupBy({
      by: ['userId', 'restaurantId'],
      having: {
        userId: {
          _count: {
            gt: 1
          }
        }
      },
      _count: {
        id: true
      }
    });

    if (remainingDuplicates.length === 0) {
      console.log('✅ No duplicate RSVPs remaining');
    } else {
      console.log(`⚠️  Warning: ${remainingDuplicates.length} user-restaurant pairs still have duplicates`);
    }

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the cleanup
cleanupDuplicateRSVPs();
