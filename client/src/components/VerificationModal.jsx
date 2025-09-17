import React, { useState, useEffect, useRef } from 'react';
import PhotoVerification from './PhotoVerification';
import StarRating from './StarRating';
import './VerificationModal.css';

const VerificationModal = ({ 
  isOpen, 
  onClose, 
  restaurantId, 
  restaurantName, 
  visitDate,
  onVerificationSubmit 
}) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [photoData, setPhotoData] = useState(null);
  const [rating, setRating] = useState(0);
  const [review, setReview] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  
  const modalRef = useRef(null);
  const firstInputRef = useRef(null);

  // Reset modal state when opened
  useEffect(() => {
    if (isOpen) {
      setCurrentStep(1);
      setPhotoData(null);
      setRating(0);
      setReview('');
      setError(null);
      setSuccess(null);
      setIsSubmitting(false);
    }
  }, [isOpen]);

  // Focus management
  useEffect(() => {
    if (isOpen && modalRef.current) {
      modalRef.current.focus();
    }
  }, [isOpen, currentStep]);

  const handleClose = () => {
    if (!isSubmitting) {
      onClose();
    }
  };

  const handleBackdropClick = (e) => {
    if (e.target === e.currentTarget && !isSubmitting) {
      handleClose();
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Escape' && !isSubmitting) {
      handleClose();
    }
  };

  const handlePhotoSubmit = (photo) => {
    setPhotoData(photo);
    setCurrentStep(2);
  };

  const handleRatingChange = (newRating) => {
    setRating(newRating);
  };

  const handleReviewChange = (e) => {
    setReview(e.target.value);
  };

  const handleNext = () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmit = async () => {
    if (!photoData || rating === 0) {
      setError('Please complete all required steps');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const verificationData = {
        restaurantId,
        restaurantName,
        visitDate,
        photo: photoData.photo,
        fileName: photoData.fileName,
        fileSize: photoData.fileSize,
        fileType: photoData.fileType,
        rating: rating,
        review: review.trim(),
        timestamp: new Date().toISOString()
      };

      await onVerificationSubmit(verificationData);
      
      setSuccess('Verification submitted successfully!');
      
      // Close modal after a short delay
      setTimeout(() => {
        handleClose();
      }, 2000);

    } catch (err) {
      console.error('Error submitting verification:', err);
      setError(err.message || 'Failed to submit verification. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getStepTitle = () => {
    switch (currentStep) {
      case 1:
        return 'Upload Photo';
      case 2:
        return 'Rate Experience';
      case 3:
        return 'Add Review';
      default:
        return 'Verify Visit';
    }
  };

  const getStepDescription = () => {
    switch (currentStep) {
      case 1:
        return 'Take a photo or upload from your gallery to verify your visit';
      case 2:
        return 'How would you rate your experience?';
      case 3:
        return 'Share your thoughts about the visit (optional)';
      default:
        return '';
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 1:
        return photoData !== null;
      case 2:
        return rating > 0;
      case 3:
        return true; // Review is optional
      default:
        return false;
    }
  };

  if (!isOpen) return null;

  return (
    <div 
      className="verification-modal-overlay"
      onClick={handleBackdropClick}
      onKeyDown={handleKeyDown}
    >
      <div 
        className="verification-modal"
        ref={modalRef}
        tabIndex={-1}
        role="dialog"
        aria-labelledby="verification-modal-title"
        aria-describedby="verification-modal-description"
      >
        {/* Header */}
        <div className="modal-header">
          <div className="modal-title-section">
            <h2 id="verification-modal-title" className="modal-title">
              Verify Your Visit
            </h2>
            <p className="restaurant-info">
              {restaurantName} • {visitDate}
            </p>
          </div>
          <button 
            className="modal-close-button"
            onClick={handleClose}
            disabled={isSubmitting}
            aria-label="Close verification modal"
          >
            ✕
          </button>
        </div>

        {/* Progress Indicator */}
        <div className="progress-indicator">
          {[1, 2, 3].map((step) => (
            <div key={step} className={`progress-step ${step <= currentStep ? 'active' : ''}`}>
              <div className="step-number">{step}</div>
              <div className="step-label">
                {step === 1 ? 'Photo' : step === 2 ? 'Rating' : 'Review'}
              </div>
            </div>
          ))}
        </div>

        {/* Content */}
        <div className="modal-content">
          <div className="step-header">
            <h3 className="step-title">{getStepTitle()}</h3>
            <p className="step-description">{getStepDescription()}</p>
          </div>

          <div className="step-content">
            {currentStep === 1 && (
              <PhotoVerification
                restaurantId={restaurantId}
                restaurantName={restaurantName}
                visitDate={visitDate}
                onPhotoSubmit={handlePhotoSubmit}
              />
            )}

            {currentStep === 2 && (
              <div className="rating-step">
                <StarRating
                  initialRating={rating}
                  onRatingChange={handleRatingChange}
                  size="large"
                  showLabel={true}
                />
                <div className="rating-tips">
                  <p>💡 Your rating helps other food club members discover great places!</p>
                </div>
              </div>
            )}

            {currentStep === 3 && (
              <div className="review-step">
                <textarea
                  ref={firstInputRef}
                  className="review-textarea"
                  placeholder="Share your thoughts about the food, service, atmosphere, or anything else that made your visit memorable..."
                  value={review}
                  onChange={handleReviewChange}
                  maxLength={500}
                  rows={6}
                  disabled={isSubmitting}
                />
                <div className="character-count">
                  {review.length}/500 characters
                </div>
                <div className="review-tips">
                  <p>💡 Your review will help other members decide where to go!</p>
                </div>
              </div>
            )}
          </div>

          {/* Error/Success Messages */}
          {error && (
            <div className="error-message">
              <span className="error-icon">❌</span>
              {error}
            </div>
          )}

          {success && (
            <div className="success-message">
              <span className="success-icon">✅</span>
              {success}
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="modal-actions">
            <div className="action-buttons">
              {currentStep > 1 && (
                <button
                  className="back-button"
                  onClick={handleBack}
                  disabled={isSubmitting}
                >
                  <span className="button-icon">←</span>
                  Back
                </button>
              )}

              {currentStep < 3 ? (
                <button
                  className="next-button"
                  onClick={handleNext}
                  disabled={!canProceed() || isSubmitting}
                >
                  Next
                  <span className="button-icon">→</span>
                </button>
              ) : (
                <button
                  className="submit-button"
                  onClick={handleSubmit}
                  disabled={!canProceed() || isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <span className="loading-spinner"></span>
                      Submitting...
                    </>
                  ) : (
                    <>
                      <span className="button-icon">✅</span>
                      Submit Verification
                    </>
                  )}
                </button>
              )}
            </div>

            <button
              className="cancel-button"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VerificationModal;
