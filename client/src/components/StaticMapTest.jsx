import React, { useState } from 'react';
import StaticMap from './StaticMap';
import { getStaticMapUrl, isStaticMapsConfigured } from '../utils/staticMapUtils';

const StaticMapTest = () => {
  const [showTest, setShowTest] = useState(false);

  // Test restaurant data
  const testRestaurant = {
    name: 'Franklin Barbecue',
    address: '900 E 11th St, Austin, TX 78702',
    coordinates: {
      latitude: 30.2701,
      longitude: -97.7312
    }
  };

  const handleLoadInteractive = () => {
    console.log('Load interactive map clicked');
    setShowTest(true);
  };

  const testStaticMapUrl = getStaticMapUrl(testRestaurant, {
    width: 600,
    height: 400,
    showMarker: true,
    markerColor: 'red',
    markerLabel: 'F'
  });

  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      <h2>Static Map Test</h2>
      
      <div style={{ marginBottom: '20px' }}>
        <h3>Configuration Status</h3>
        <p>Static Maps Configured: {isStaticMapsConfigured() ? '✅ Yes' : '❌ No'}</p>
        <p>Google Maps API Key: {process.env.REACT_APP_GOOGLE_MAPS_API_KEY ? '✅ Set' : '❌ Missing'}</p>
      </div>

      <div style={{ marginBottom: '20px' }}>
        <h3>Test Restaurant</h3>
        <p><strong>Name:</strong> {testRestaurant.name}</p>
        <p><strong>Address:</strong> {testRestaurant.address}</p>
        <p><strong>Coordinates:</strong> {testRestaurant.coordinates.latitude}, {testRestaurant.coordinates.longitude}</p>
      </div>

      <div style={{ marginBottom: '20px' }}>
        <h3>Generated Static Map URL</h3>
        <p style={{ wordBreak: 'break-all', fontSize: '12px', background: '#f5f5f5', padding: '10px', borderRadius: '4px' }}>
          {testStaticMapUrl}
        </p>
      </div>

      <div style={{ marginBottom: '20px' }}>
        <h3>Static Map Component</h3>
        <StaticMap
          restaurant={testRestaurant}
          onClick={handleLoadInteractive}
          showLoadButton={true}
          loadButtonText="Load Interactive Map"
          options={{
            width: 600,
            height: 400,
            showMarker: true,
            markerColor: 'red',
            markerLabel: 'F'
          }}
        />
      </div>

      {showTest && (
        <div style={{ marginTop: '20px', padding: '20px', background: '#e8f5e8', borderRadius: '8px' }}>
          <h3>✅ Interactive Map Loaded!</h3>
          <p>This would normally show the full interactive Google Map component.</p>
        </div>
      )}

      <div style={{ marginTop: '20px' }}>
        <h3>Test Different Options</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
          <div>
            <h4>Small Map</h4>
            <StaticMap
              restaurant={testRestaurant}
              onClick={handleLoadInteractive}
              showLoadButton={false}
              options={{ width: 200, height: 150 }}
            />
          </div>
          
          <div>
            <h4>Blue Marker</h4>
            <StaticMap
              restaurant={testRestaurant}
              onClick={handleLoadInteractive}
              showLoadButton={false}
              options={{ 
                width: 200, 
                height: 150, 
                markerColor: 'blue', 
                markerLabel: 'B' 
              }}
            />
          </div>
          
          <div>
            <h4>No Marker</h4>
            <StaticMap
              restaurant={testRestaurant}
              onClick={handleLoadInteractive}
              showLoadButton={false}
              options={{ 
                width: 200, 
                height: 150, 
                showMarker: false 
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default StaticMapTest;
