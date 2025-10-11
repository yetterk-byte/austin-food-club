/*
  Simple smoke test:
  1) Request verification code (mock)
  2) Verify code → get auth token
  3) Fetch featured restaurant
  4) Create RSVP with token
  5) List verified visits with token
*/

const axios = require('axios');

const BASE_URL = process.env.SMOKE_BASE_URL || 'http://localhost:3001';
const PHONE = process.env.SMOKE_PHONE || '+15555550123';
const NAME = process.env.SMOKE_NAME || 'Smoke Test User';

async function main() {
  try {
    console.log(`🔎 Using base URL: ${BASE_URL}`);

    // 1) Send verification code (mock)
    console.log('📨 Sending verification code (mock)...');
    const sendRes = await axios.post(`${BASE_URL}/api/verification/send-code`, new URLSearchParams({
      phone: PHONE
    }), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    if (!sendRes.data?.success) throw new Error('send-code failed');
    const mockCode = sendRes.data?.data?.mockCode;
    console.log(`✅ Verification code sent. mockCode=${mockCode}`);

    // 2) Verify code → get token
    console.log('🔐 Verifying code...');
    const verifyRes = await axios.post(`${BASE_URL}/api/verification/verify-code`, new URLSearchParams({
      phone: PHONE,
      code: mockCode,
      name: NAME,
    }), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    if (!verifyRes.data?.success) throw new Error('verify-code failed');
    const authToken = verifyRes.data?.data?.authToken || verifyRes.data?.data?.sessionToken;
    if (!authToken) throw new Error('No auth token returned');
    console.log('✅ Verified. Token acquired.');

    // 3) Fetch featured restaurant
    console.log('🍽️ Fetching featured restaurant...');
    const featuredRes = await axios.get(`${BASE_URL}/api/restaurants/featured`);
    if (!featuredRes.data?.success) throw new Error('featured fetch failed');
    const restaurant = featuredRes.data?.restaurant;
    const restaurantId = restaurant?.id;
    console.log(`✅ Featured restaurant: ${restaurant?.name} (${restaurantId})`);

    // 4) Create RSVP
    console.log('🗓️ Creating RSVP...');
    const rsvpRes = await axios.post(`${BASE_URL}/api/rsvp`, {
      restaurantId: restaurantId,
      day: 'friday',
      status: 'going',
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      }
    });
    if (!(rsvpRes.status === 201 || rsvpRes.data?.success)) throw new Error('RSVP failed');
    console.log('✅ RSVP created.');

    // 5) List verified visits (auth required)
    console.log('📸 Fetching verified visits...');
    const visitsRes = await axios.get(`${BASE_URL}/api/verified-visits`, {
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      }
    });
    if (!(visitsRes.status === 200)) throw new Error('verified visits failed');
    const count = Array.isArray(visitsRes.data?.data) ? visitsRes.data.data.length : (visitsRes.data?.total || 0);
    console.log(`✅ Verified visits accessible. Count≈${count}`);

    console.log('\n🎉 Smoke test passed.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Smoke test failed:', err?.response?.data || err?.message || err);
    process.exit(1);
  }
}

main();


