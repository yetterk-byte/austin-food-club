import React, { useState, useRef } from 'react';
import photoService from '../services/photoService';
import './PhotoVerification.css';

const PhotoVerification = ({ 
  restaurantId, 
  restaurantName, 
  visitDate, 
  onPhotoSubmit 
}) => {
  const [selectedPhoto, setSelectedPhoto] = useState(null);
  const [photoPreview, setPhotoPreview] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [cameraError, setCameraError] = useState(null);
  
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  const handleCameraCapture = () => {
    setError(null);
    setCameraError(null);
    
    if (cameraInputRef.current) {
      cameraInputRef.current.click();
    }
  };

  const handleGalleryUpload = () => {
    setError(null);
    setCameraError(null);
    
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleFileChange = async (event) => {
    const file = event.target.files[0];
    
    if (!file) return;

    // Validate the file using photo service
    const validation = photoService.validateImage(file);
    if (!validation.isValid) {
      setError(validation.error);
      return;
    }

    try {
      // Compress the image for better performance
      const compressedFile = await photoService.compressImage(file, {
        isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
      });
      
      setSelectedPhoto(compressedFile);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setPhotoPreview(e.target.result);
      };
      reader.readAsDataURL(compressedFile);
      
      setError(null);
      setSuccess(null);
    } catch (err) {
      setError('Failed to process image. Please try again.');
      console.error('Image processing error:', err);
    }
  };

  const convertToBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = error => reject(error);
    });
  };

  const handleSubmit = async () => {
    if (!selectedPhoto) {
      setError('Please select a photo first');
      return;
    }

    setIsUploading(true);
    setError(null);
    setSuccess(null);

    try {
      // Upload photo using photo service
      const uploadResult = await photoService.uploadPhoto(
        selectedPhoto,
        'current-user', // This should be passed as a prop
        restaurantId,
        (progress) => {
          console.log(`Upload progress: ${progress}%`);
        },
        {
          isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
        }
      );

      if (!uploadResult.success) {
        throw new Error(uploadResult.error);
      }
      
      // Prepare photo data
      const photoData = {
        restaurantId,
        restaurantName,
        visitDate,
        photoUrl: uploadResult.photoUrl,
        fileName: uploadResult.fileName || selectedPhoto.name,
        fileSize: selectedPhoto.size,
        fileType: selectedPhoto.type,
        timestamp: new Date().toISOString()
      };

      // Call the parent component's submit handler
      await onPhotoSubmit(photoData);
      
      setSuccess('Photo uploaded successfully!');
      
      // Reset form after successful submission
      setTimeout(() => {
        setSelectedPhoto(null);
        setPhotoPreview(null);
        setSuccess(null);
      }, 2000);

    } catch (err) {
      console.error('Error submitting photo:', err);
      setError(err.message || 'Failed to submit photo. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleRetake = () => {
    setSelectedPhoto(null);
    setPhotoPreview(null);
    setError(null);
    setSuccess(null);
    
    // Clear file inputs
    if (fileInputRef.current) fileInputRef.current.value = '';
    if (cameraInputRef.current) cameraInputRef.current.value = '';
  };

  const handleCameraError = () => {
    setCameraError('Camera access denied or not available. Please use gallery upload instead.');
  };

  return (
    <div className="photo-verification">
      <div className="photo-verification-header">
        <h2>Verify Your Visit</h2>
        <p className="restaurant-name">{restaurantName}</p>
        <p className="visit-date">{visitDate}</p>
      </div>

      <div className="photo-verification-content">
        {!photoPreview ? (
          <div className="photo-upload-section">
            <div className="upload-options">
              <button 
                className="camera-button"
                onClick={handleCameraCapture}
                disabled={isUploading}
              >
                <span className="button-icon">📷</span>
                <span className="button-text">Take Photo</span>
              </button>
              
              <button 
                className="gallery-button"
                onClick={handleGalleryUpload}
                disabled={isUploading}
              >
                <span className="button-icon">🖼️</span>
                <span className="button-text">Choose from Gallery</span>
              </button>
            </div>

            {cameraError && (
              <div className="error-message">
                <span className="error-icon">⚠️</span>
                {cameraError}
              </div>
            )}

          </div>
        ) : (
          <div className="photo-preview-section">
            <div className="photo-preview">
              <img src={photoPreview} alt="Visit verification" />
            </div>
            
            <div className="preview-actions">
              <button 
                className="retake-button"
                onClick={handleRetake}
                disabled={isUploading}
              >
                <span className="button-icon">🔄</span>
                Retake Photo
              </button>
              
              <button 
                className="next-button"
                onClick={handleSubmit}
                disabled={isUploading}
              >
                {isUploading ? (
                  <>
                    <span className="loading-spinner"></span>
                    Processing...
                  </>
                ) : (
                  <>
                    <span className="button-icon">➡️</span>
                    Next Step
                  </>
                )}
              </button>
            </div>
          </div>
        )}

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
      </div>

      {/* Hidden file inputs */}
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileChange}
        accept="image/*"
        style={{ display: 'none' }}
      />
      
      <input
        type="file"
        ref={cameraInputRef}
        onChange={handleFileChange}
        accept="image/*"
        capture="environment"
        style={{ display: 'none' }}
        onError={handleCameraError}
      />
    </div>
  );
};

export default PhotoVerification;
