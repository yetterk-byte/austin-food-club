const { PrismaClient } = require('@prisma/client');

// Create a singleton Prisma client instance
let prisma;

const getPrismaClient = () => {
  if (!prisma) {
    prisma = new PrismaClient();
  }
  return prisma;
};

// Export both the client and the getter function
module.exports = {
  prisma: getPrismaClient(),
  getPrismaClient
};

