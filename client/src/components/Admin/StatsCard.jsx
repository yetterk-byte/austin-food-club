import React from 'react';

const StatsCard = ({ title, value, icon, change, changeType = 'neutral' }) => {
  const getChangeClass = () => {
    switch (changeType) {
      case 'positive': return 'positive';
      case 'negative': return 'negative';
      default: return '';
    }
  };

  return (
    <div className="stat-card">
      <div className="stat-card-header">
        <span className="stat-card-icon">{icon}</span>
        <h3 className="stat-card-title">{title}</h3>
      </div>
      <div className="stat-card-value">{value.toLocaleString()}</div>
      {change && (
        <div className={`stat-card-change ${getChangeClass()}`}>
          {change}
        </div>
      )}
    </div>
  );
};

export default StatsCard;
