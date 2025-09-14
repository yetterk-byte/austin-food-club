# Austin Food Club 🍽️

A full-stack mobile-first web application for discovering and RSVPing to the best restaurants in Austin, Texas.

## 🚀 Features

- **Restaurant Discovery** - Weekly featured restaurants with detailed information
- **RSVP System** - Reserve your spot for restaurant visits
- **Wishlist** - Save restaurants you want to try
- **User Profiles** - Track your dining history and stats
- **Phone Authentication** - Secure login with SMS verification
- **Dark Theme** - Sleek, mobile-first design

## 🛠️ Tech Stack

### Frontend
- **React 18** - Modern React with hooks
- **React Router** - Client-side routing
- **Axios** - HTTP client for API calls
- **Supabase** - Authentication and real-time features
- **CSS3** - Custom dark theme styling

### Backend
- **Node.js** - JavaScript runtime
- **Express.js** - Web framework
- **Prisma** - Database ORM
- **SQLite** - Local database
- **CORS** - Cross-origin resource sharing

## 📁 Project Structure

```
austin-food-club/
├── client/                 # React frontend
│   ├── public/            # Static assets
│   ├── src/
│   │   ├── components/    # Reusable UI components
│   │   ├── pages/         # Page components
│   │   ├── services/      # API and Supabase services
│   │   └── context/       # React context providers
│   └── package.json
├── server/                # Express backend
│   ├── src/
│   │   └── server.js      # Main server file
│   ├── prisma/
│   │   └── schema.prisma  # Database schema
│   └── package.json
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- Node.js (v18 or higher)
- npm or yarn
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd austin-food-club
   ```

2. **Install frontend dependencies**
   ```bash
   cd client
   npm install
   ```

3. **Install backend dependencies**
   ```bash
   cd ../server
   npm install
   ```

4. **Set up the database**
   ```bash
   cd server
   npx prisma generate
   npx prisma migrate dev --name init
   ```

5. **Set up environment variables**
   
   Create `client/.env`:
   ```env
   REACT_APP_SUPABASE_URL=your_supabase_url
   REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

6. **Start the development servers**
   
   Terminal 1 (Backend):
   ```bash
   cd server
   npm start
   ```
   
   Terminal 2 (Frontend):
   ```bash
   cd client
   npm start
   ```

7. **Open your browser**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001

## 📱 Pages & Features

### Current Page
- Featured restaurant details
- RSVP functionality with day selection
- Restaurant stats and information

### Wishlist Page
- Search and manage saved restaurants
- Add/remove restaurants from wishlist

### Profile Page
- User statistics and verified visits
- Friends list and social features
- RSVP history

## 🗄️ Database Schema

The app uses Prisma with SQLite and includes these models:

- **User** - User accounts and profiles
- **Restaurant** - Restaurant information
- **RSVP** - User reservations
- **Wishlist** - Saved restaurants
- **VerifiedVisit** - Confirmed restaurant visits
- **Friendship** - User relationships

## 🔐 Authentication

The app supports multiple authentication methods:

- **Phone Authentication** - SMS OTP verification
- **Email Authentication** - Traditional email/password
- **Supabase Integration** - Secure user management

## 🎨 Design

- **Mobile-first** responsive design
- **Dark theme** with charcoal and white accents
- **Modern UI** with smooth animations
- **Accessibility** considerations

## 🧪 Testing

```bash
# Test backend API
curl http://localhost:3001/api/test

# Test restaurant endpoint
curl http://localhost:3001/api/restaurants/current

# Test RSVP endpoint
curl -X POST http://localhost:3001/api/rsvp \
  -H "Content-Type: application/json" \
  -d '{"userId":"user123","day":"wednesday","status":"going"}'
```

## 📦 Deployment

### Frontend (Vercel/Netlify)
1. Build the React app: `npm run build`
2. Deploy the `build` folder

### Backend (Railway/Heroku)
1. Set up environment variables
2. Deploy with database migration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 👥 Team

Built with ❤️ for the Austin food community.

---

**Note**: This is a demo project showcasing full-stack development with React, Node.js, and modern web technologies.
