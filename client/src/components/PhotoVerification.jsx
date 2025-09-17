import React, { useState, useRef, useEffect } from 'react';
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
  const [isProcessing, setIsProcessing] = useState(false);
  const [zoom, setZoom] = useState(1);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [lastTouchDistance, setLastTouchDistance] = useState(0);
  
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);
  const previewRef = useRef(null);
  const canvasRef = useRef(null);

  // Auto-rotate correction for mobile photos
  const correctImageOrientation = (file) => {
    return new Promise((resolve) => {
      const img = new Image();
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      
      img.onload = async () => {
        try {
          // Get EXIF orientation
          const orientation = await getImageOrientation(file);
          
          // Set canvas dimensions based on orientation
          if (orientation >= 5) {
            canvas.width = img.height;
            canvas.height = img.width;
          } else {
            canvas.width = img.width;
            canvas.height = img.height;
          }
          
          // Apply rotation based on EXIF data
          switch (orientation) {
            case 2:
              ctx.transform(-1, 0, 0, 1, canvas.width, 0);
              break;
            case 3:
              ctx.transform(-1, 0, 0, -1, canvas.width, canvas.height);
              break;
            case 4:
              ctx.transform(1, 0, 0, -1, 0, canvas.height);
              break;
            case 5:
              ctx.transform(0, 1, 1, 0, 0, 0);
              break;
            case 6:
              ctx.transform(0, 1, -1, 0, canvas.height, 0);
              break;
            case 7:
              ctx.transform(0, -1, -1, 0, canvas.height, canvas.width);
              break;
            case 8:
              ctx.transform(0, -1, 1, 0, 0, canvas.width);
              break;
            default:
              break;
          }
          
          ctx.drawImage(img, 0, 0);
          
          canvas.toBlob((blob) => {
            const correctedFile = new File([blob], file.name, {
              type: file.type,
              lastModified: Date.now()
            });
            resolve(correctedFile);
          }, file.type, 0.9);
        } catch (error) {
          console.warn('Could not correct image orientation:', error);
          resolve(file); // Return original file if correction fails
        }
      };
      
      img.src = URL.createObjectURL(file);
    });
  };

  // Get EXIF orientation from file
  const getImageOrientation = (file) => {
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const view = new DataView(e.target.result);
        if (view.getUint16(0, false) !== 0xFFD8) {
          resolve(1);
          return;
        }
        
        const length = view.byteLength;
        let offset = 2;
        
        while (offset < length) {
          const marker = view.getUint16(offset, false);
          if (marker === 0xFFE1) {
            if (view.getUint32(offset + 4, false) !== 0x45786966) {
              offset += 2;
              continue;
            }
            
            const little = view.getUint16(offset + 10, false) === 0x4949;
            const ifdOffset = view.getUint32(offset + 6, little);
            const tags = view.getUint16(ifdOffset, little);
            
            for (let i = 0; i < tags; i++) {
              const tag = view.getUint16(ifdOffset + 2 + (i * 12), little);
              if (tag === 0x0112) {
                const orientation = view.getUint16(ifdOffset + 2 + (i * 12) + 8, little);
                resolve(orientation);
                return;
              }
            }
          } else if ((marker & 0xFF00) !== 0xFF00) {
            break;
          } else {
            offset += 2;
          }
        }
        resolve(1);
      };
      reader.readAsArrayBuffer(file.slice(0, 64 * 1024));
    });
  };

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
      setIsProcessing(true);
      setError(null);
      setSuccess(null);

      // Auto-rotate correction for mobile photos
      const correctedFile = await correctImageOrientation(file);
      
      // Compress the image for better performance
      const compressedFile = await photoService.compressImage(correctedFile, {
        isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
      });
      
      setSelectedPhoto(compressedFile);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setPhotoPreview(e.target.result);
        // Reset zoom and position for new image
        setZoom(1);
        setPosition({ x: 0, y: 0 });
      };
      reader.readAsDataURL(compressedFile);
      
    } catch (err) {
      setError('Failed to process image. Please try again.');
      console.error('Image processing error:', err);
    } finally {
      setIsProcessing(false);
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

  // Touch gesture handlers for pinch-to-zoom and drag
  const handleTouchStart = (e) => {
    e.preventDefault();
    
    if (e.touches.length === 1) {
      // Single touch - start drag
      setIsDragging(true);
      setDragStart({
        x: e.touches[0].clientX - position.x,
        y: e.touches[0].clientY - position.y
      });
    } else if (e.touches.length === 2) {
      // Two touches - start pinch
      const distance = Math.sqrt(
        Math.pow(e.touches[0].clientX - e.touches[1].clientX, 2) +
        Math.pow(e.touches[0].clientY - e.touches[1].clientY, 2)
      );
      setLastTouchDistance(distance);
    }
  };

  const handleTouchMove = (e) => {
    e.preventDefault();
    
    if (e.touches.length === 1 && isDragging) {
      // Single touch - drag
      setPosition({
        x: e.touches[0].clientX - dragStart.x,
        y: e.touches[0].clientY - dragStart.y
      });
    } else if (e.touches.length === 2) {
      // Two touches - pinch to zoom
      const distance = Math.sqrt(
        Math.pow(e.touches[0].clientX - e.touches[1].clientX, 2) +
        Math.pow(e.touches[0].clientY - e.touches[1].clientY, 2)
      );
      
      if (lastTouchDistance > 0) {
        const scale = distance / lastTouchDistance;
        const newZoom = Math.min(Math.max(zoom * scale, 0.5), 3);
        setZoom(newZoom);
      }
      setLastTouchDistance(distance);
    }
  };

  const handleTouchEnd = (e) => {
    e.preventDefault();
    setIsDragging(false);
    setLastTouchDistance(0);
  };

  // Mouse handlers for desktop
  const handleMouseDown = (e) => {
    if (e.button === 0) { // Left mouse button
      setIsDragging(true);
      setDragStart({
        x: e.clientX - position.x,
        y: e.clientY - position.y
      });
    }
  };

  const handleMouseMove = (e) => {
    if (isDragging) {
      setPosition({
        x: e.clientX - dragStart.x,
        y: e.clientY - dragStart.y
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  // Wheel zoom for desktop
  const handleWheel = (e) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    const newZoom = Math.min(Math.max(zoom * delta, 0.5), 3);
    setZoom(newZoom);
  };

  // Reset zoom and position
  const resetView = () => {
    setZoom(1);
    setPosition({ x: 0, y: 0 });
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
    setZoom(1);
    setPosition({ x: 0, y: 0 });
    setIsDragging(false);
    
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
            {isProcessing ? (
              <div className="loading-skeleton">
                <div className="skeleton-image"></div>
                <div className="skeleton-text">
                  <div className="skeleton-line"></div>
                  <div className="skeleton-line short"></div>
                </div>
                <div className="processing-indicator">
                  <div className="spinner"></div>
                  <p>Processing image...</p>
                </div>
              </div>
            ) : (
              <>
                <div className="photo-preview-container">
                  <div 
                    className="photo-preview"
                    ref={previewRef}
                    onTouchStart={handleTouchStart}
                    onTouchMove={handleTouchMove}
                    onTouchEnd={handleTouchEnd}
                    onMouseDown={handleMouseDown}
                    onMouseMove={handleMouseMove}
                    onMouseUp={handleMouseUp}
                    onMouseLeave={handleMouseUp}
                    onWheel={handleWheel}
                    style={{
                      transform: `scale(${zoom}) translate(${position.x}px, ${position.y}px)`,
                      cursor: isDragging ? 'grabbing' : 'grab'
                    }}
                  >
                    <img 
                      src={photoPreview} 
                      alt="Visit verification" 
                      draggable={false}
                      style={{
                        transform: 'scale(1)',
                        transition: isDragging ? 'none' : 'transform 0.1s ease-out'
                      }}
                    />
                  </div>
                  
                  {/* Zoom controls */}
                  <div className="zoom-controls">
                    <button 
                      className="zoom-btn"
                      onClick={() => setZoom(Math.max(zoom - 0.2, 0.5))}
                      disabled={zoom <= 0.5}
                    >
                      −
                    </button>
                    <span className="zoom-level">{Math.round(zoom * 100)}%</span>
                    <button 
                      className="zoom-btn"
                      onClick={() => setZoom(Math.min(zoom + 0.2, 3))}
                      disabled={zoom >= 3}
                    >
                      +
                    </button>
                    <button 
                      className="reset-zoom-btn"
                      onClick={resetView}
                    >
                      Reset
                    </button>
                  </div>
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
              </>
            )}
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
        multiple={false}
        style={{ display: 'none' }}
      />
      
      <input
        type="file"
        ref={cameraInputRef}
        onChange={handleFileChange}
        accept="image/*"
        capture="environment"
        multiple={false}
        style={{ display: 'none' }}
        onError={handleCameraError}
      />
    </div>
  );
};

export default PhotoVerification;
