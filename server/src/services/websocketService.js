const { Server } = require('socket.io');

class WebSocketService {
  constructor() {
    this.io = null;
    this.connectedClients = new Map();
  }

  initialize(server) {
    this.io = new Server(server, {
      cors: {
        origin: ["http://localhost:3000", "http://localhost:8080", "http://localhost:3001"],
        methods: ["GET", "POST"]
      }
    });

    this.io.on('connection', (socket) => {
      console.log(`🔌 WebSocket client connected: ${socket.id}`);
      
      // Store client info
      this.connectedClients.set(socket.id, {
        id: socket.id,
        connectedAt: new Date(),
        rooms: new Set()
      });

      // Handle room joining (for city-specific updates)
      socket.on('join-city', (cityId) => {
        socket.join(`city-${cityId}`);
        const client = this.connectedClients.get(socket.id);
        if (client) {
          client.rooms.add(`city-${cityId}`);
        }
        console.log(`🏙️ Client ${socket.id} joined city room: city-${cityId}`);
      });

      // Handle room leaving
      socket.on('leave-city', (cityId) => {
        socket.leave(`city-${cityId}`);
        const client = this.connectedClients.get(socket.id);
        if (client) {
          client.rooms.delete(`city-${cityId}`);
        }
        console.log(`🏙️ Client ${socket.id} left city room: city-${cityId}`);
      });

      // Handle admin dashboard connection
      socket.on('join-admin', () => {
        socket.join('admin-dashboard');
        const client = this.connectedClients.get(socket.id);
        if (client) {
          client.rooms.add('admin-dashboard');
        }
        console.log(`👨‍💼 Admin client ${socket.id} joined admin dashboard`);
      });

      // Handle disconnection
      socket.on('disconnect', () => {
        console.log(`🔌 WebSocket client disconnected: ${socket.id}`);
        this.connectedClients.delete(socket.id);
      });
    });

    console.log('✅ WebSocket service initialized');
  }

  // Broadcast to all admin dashboard clients
  broadcastToAdmin(event, data) {
    if (this.io) {
      this.io.to('admin-dashboard').emit(event, data);
      console.log(`📡 Broadcasted to admin dashboard: ${event}`);
    }
  }

  // Broadcast to specific city room
  broadcastToCity(cityId, event, data) {
    if (this.io) {
      this.io.to(`city-${cityId}`).emit(event, data);
      console.log(`📡 Broadcasted to city ${cityId}: ${event}`);
    }
  }

  // Broadcast to all connected clients
  broadcastToAll(event, data) {
    if (this.io) {
      this.io.emit(event, data);
      console.log(`📡 Broadcasted to all clients: ${event}`);
    }
  }

  // Send to specific client
  sendToClient(socketId, event, data) {
    if (this.io) {
      this.io.to(socketId).emit(event, data);
      console.log(`📡 Sent to client ${socketId}: ${event}`);
    }
  }

  // Get connected clients count
  getConnectedClientsCount() {
    return this.connectedClients.size;
  }

  // Get clients in admin dashboard
  getAdminClientsCount() {
    return Array.from(this.connectedClients.values()).filter(
      client => client.rooms.has('admin-dashboard')
    ).length;
  }
}

module.exports = new WebSocketService();
