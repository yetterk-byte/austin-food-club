import React from 'react';
import './FriendsModal.css';

const FriendsModal = ({ isOpen, onClose }) => {
  const friends = [
    {
      id: 1,
      name: 'Sarah Mitchell',
      avatar: 'SM',
      stats: { verified: 8, thisMonth: 2 },
      status: 'online'
    },
    {
      id: 2,
      name: 'Alex Thompson',
      avatar: 'AT',
      stats: { verified: 15, thisMonth: 4 },
      status: 'offline'
    },
    {
      id: 3,
      name: 'Emma Rodriguez',
      avatar: 'ER',
      stats: { verified: 12, thisMonth: 3 },
      status: 'online'
    },
    {
      id: 4,
      name: 'David Chen',
      avatar: 'DC',
      stats: { verified: 6, thisMonth: 1 },
      status: 'offline'
    },
    {
      id: 5,
      name: 'Lisa Wang',
      avatar: 'LW',
      stats: { verified: 20, thisMonth: 5 },
      status: 'online'
    },
    {
      id: 6,
      name: 'Mike Johnson',
      avatar: 'MJ',
      stats: { verified: 9, thisMonth: 2 },
      status: 'offline'
    },
    {
      id: 7,
      name: 'Rachel Green',
      avatar: 'RG',
      stats: { verified: 14, thisMonth: 3 },
      status: 'online'
    },
    {
      id: 8,
      name: 'Tom Wilson',
      avatar: 'TW',
      stats: { verified: 7, thisMonth: 1 },
      status: 'offline'
    }
  ];

  if (!isOpen) return null;

  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  const handleMessageClick = (friendId) => {
    console.log(`Message friend ${friendId}`);
    // In a real app, this would open a chat or navigate to messaging
  };

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className="friends-modal">
        {/* Header */}
        <div className="modal-header">
          <h2>Friends ({friends.length})</h2>
          <button className="close-button" onClick={onClose}>
            ×
          </button>
        </div>

        {/* Friends List */}
        <div className="friends-list">
          {friends.map((friend) => (
            <div key={friend.id} className="friend-item">
              <div className="friend-avatar">
                {friend.avatar}
                <div className={`status-indicator ${friend.status}`}></div>
              </div>
              
              <div className="friend-info">
                <h3 className="friend-name">{friend.name}</h3>
                <div className="friend-stats">
                  <span className="stat">
                    {friend.stats.verified} verified
                  </span>
                  <span className="stat">
                    {friend.stats.thisMonth} this month
                  </span>
                </div>
              </div>
              
              <button 
                className="message-button"
                onClick={() => handleMessageClick(friend.id)}
              >
                Message
              </button>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="modal-footer">
          <button className="add-friends-button">
            Add Friends
          </button>
        </div>
      </div>
    </div>
  );
};

export default FriendsModal;

