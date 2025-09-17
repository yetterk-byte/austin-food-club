/**
 * Photo Service - Handles image compression, validation, and upload
 * Supports both base64 encoding and Supabase storage upload
 */

// Configuration
const CONFIG = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
  ALLOWED_TYPES: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
  COMPRESSION: {
    MAX_WIDTH: 1920,
    MAX_HEIGHT: 1080,
    QUALITY: 0.8,
    MOBILE_QUALITY: 0.7
  }
};

/**
 * Validates image file type and size
 * @param {File} file - The file to validate
 * @returns {Object} - { isValid: boolean, error?: string }
 */
export const validateImage = (file) => {
  // Check if file exists
  if (!file) {
    return { isValid: false, error: 'No file provided' };
  }

  // Check file type
  if (!CONFIG.ALLOWED_TYPES.includes(file.type)) {
    return { 
      isValid: false, 
      error: `Invalid file type. Allowed types: ${CONFIG.ALLOWED_TYPES.join(', ')}` 
    };
  }

  // Check file size
  if (file.size > CONFIG.MAX_FILE_SIZE) {
    const maxSizeMB = CONFIG.MAX_FILE_SIZE / (1024 * 1024);
    return { 
      isValid: false, 
      error: `File too large. Maximum size: ${maxSizeMB}MB` 
    };
  }

  return { isValid: true };
};

/**
 * Compresses an image file to reduce size
 * @param {File} file - The image file to compress
 * @param {Object} options - Compression options
 * @param {number} options.maxWidth - Maximum width (default: 1920)
 * @param {number} options.maxHeight - Maximum height (default: 1080)
 * @param {number} options.quality - Compression quality 0-1 (default: 0.8)
 * @param {boolean} options.isMobile - Use mobile-optimized settings
 * @returns {Promise<File>} - Compressed image file
 */
export const compressImage = (file, options = {}) => {
  return new Promise((resolve, reject) => {
    const {
      maxWidth = CONFIG.COMPRESSION.MAX_WIDTH,
      maxHeight = CONFIG.COMPRESSION.MAX_HEIGHT,
      quality = CONFIG.COMPRESSION.QUALITY,
      isMobile = false
    } = options;

    // Use mobile quality if specified
    const finalQuality = isMobile ? CONFIG.COMPRESSION.MOBILE_QUALITY : quality;

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();

    img.onload = () => {
      // Calculate new dimensions while maintaining aspect ratio
      let { width, height } = img;
      
      if (width > maxWidth || height > maxHeight) {
        const ratio = Math.min(maxWidth / width, maxHeight / height);
        width = width * ratio;
        height = height * ratio;
      }

      // Set canvas dimensions
      canvas.width = width;
      canvas.height = height;

      // Draw and compress
      ctx.drawImage(img, 0, 0, width, height);
      
      canvas.toBlob(
        (blob) => {
          if (!blob) {
            reject(new Error('Failed to compress image'));
            return;
          }

          // Create new file with compressed data
          const compressedFile = new File([blob], file.name, {
            type: file.type,
            lastModified: Date.now()
          });

          resolve(compressedFile);
        },
        file.type,
        finalQuality
      );
    };

    img.onerror = () => {
      reject(new Error('Failed to load image'));
    };

    // Load the image
    img.src = URL.createObjectURL(file);
  });
};

/**
 * Converts image file to base64 string
 * @param {File} file - The image file to convert
 * @returns {Promise<string>} - Base64 encoded string
 */
export const convertToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    
    reader.onload = () => {
      resolve(reader.result);
    };
    
    reader.onerror = () => {
      reject(new Error('Failed to convert image to base64'));
    };
    
    reader.readAsDataURL(file);
  });
};

/**
 * Generates a unique filename for photo uploads
 * @param {string} userId - User ID
 * @param {string} restaurantId - Restaurant ID
 * @param {string} fileExtension - File extension (e.g., '.jpg')
 * @returns {string} - Unique filename
 */
export const generateUniqueFilename = (userId, restaurantId, fileExtension) => {
  const timestamp = Date.now();
  const randomId = Math.random().toString(36).substring(2, 8);
  return `visits/${userId}/${restaurantId}_${timestamp}_${randomId}${fileExtension}`;
};

/**
 * Gets file extension from MIME type
 * @param {string} mimeType - MIME type (e.g., 'image/jpeg')
 * @returns {string} - File extension (e.g., '.jpg')
 */
export const getFileExtension = (mimeType) => {
  const extensions = {
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp'
  };
  return extensions[mimeType] || '.jpg';
};

/**
 * Uploads photo to Supabase storage (if configured) or returns base64
 * @param {File} file - The image file to upload
 * @param {string} userId - User ID
 * @param {string} restaurantId - Restaurant ID
 * @param {Function} onProgress - Progress callback function
 * @param {Object} options - Upload options
 * @returns {Promise<Object>} - { success: boolean, photoUrl?: string, error?: string }
 */
export const uploadPhoto = async (file, userId, restaurantId, onProgress = null, options = {}) => {
  try {
    // Validate the file first
    const validation = validateImage(file);
    if (!validation.isValid) {
      return { success: false, error: validation.error };
    }

    // Compress the image
    const compressedFile = await compressImage(file, {
      isMobile: options.isMobile || false,
      quality: options.quality
    });

    // Check if Supabase is configured
    const { createClient } = await import('@supabase/supabase-js');
    const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
    const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

    if (supabaseUrl && supabaseKey) {
      // Upload to Supabase storage
      return await uploadToSupabase(compressedFile, userId, restaurantId, onProgress);
    } else {
      // Fallback to base64 encoding
      return await uploadAsBase64(compressedFile, onProgress);
    }
  } catch (error) {
    console.error('Photo upload error:', error);
    return { 
      success: false, 
      error: error.message || 'Failed to upload photo' 
    };
  }
};

/**
 * Uploads photo to Supabase storage
 * @param {File} file - Compressed image file
 * @param {string} userId - User ID
 * @param {string} restaurantId - Restaurant ID
 * @param {Function} onProgress - Progress callback
 * @returns {Promise<Object>} - Upload result
 */
const uploadToSupabase = async (file, userId, restaurantId, onProgress) => {
  try {
    const { createClient } = await import('@supabase/supabase-js');
    const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
    const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;
    
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Generate unique filename
    const fileExtension = getFileExtension(file.type);
    const fileName = generateUniqueFilename(userId, restaurantId, fileExtension);
    
    // Upload file
    const { data, error } = await supabase.storage
      .from('visit-photos')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      throw new Error(`Supabase upload failed: ${error.message}`);
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('visit-photos')
      .getPublicUrl(fileName);

    if (onProgress) {
      onProgress(100);
    }

    return {
      success: true,
      photoUrl: urlData.publicUrl,
      fileName: fileName
    };
  } catch (error) {
    console.error('Supabase upload error:', error);
    return { 
      success: false, 
      error: error.message || 'Failed to upload to Supabase' 
    };
  }
};

/**
 * Converts photo to base64 as fallback
 * @param {File} file - Compressed image file
 * @param {Function} onProgress - Progress callback
 * @returns {Promise<Object>} - Base64 result
 */
const uploadAsBase64 = async (file, onProgress) => {
  try {
    if (onProgress) {
      onProgress(50); // Simulate progress
    }

    const base64String = await convertToBase64(file);
    
    if (onProgress) {
      onProgress(100);
    }

    return {
      success: true,
      photoUrl: base64String,
      fileName: file.name
    };
  } catch (error) {
    console.error('Base64 conversion error:', error);
    return { 
      success: false, 
      error: error.message || 'Failed to convert to base64' 
    };
  }
};

/**
 * Deletes a photo from Supabase storage
 * @param {string} photoUrl - The photo URL to delete
 * @returns {Promise<Object>} - Deletion result
 */
export const deletePhoto = async (photoUrl) => {
  try {
    // Check if it's a Supabase URL
    if (photoUrl.includes('supabase') || photoUrl.includes('storage')) {
      const { createClient } = await import('@supabase/supabase-js');
      const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
      const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseKey) {
        return { success: false, error: 'Supabase not configured' };
      }

      const supabase = createClient(supabaseUrl, supabaseKey);
      
      // Extract filename from URL
      const urlParts = photoUrl.split('/');
      const fileName = urlParts[urlParts.length - 1];
      
      // Delete from storage
      const { error } = await supabase.storage
        .from('visit-photos')
        .remove([fileName]);

      if (error) {
        throw new Error(`Supabase delete failed: ${error.message}`);
      }

      return { success: true };
    } else {
      // For base64 URLs, nothing to delete
      return { success: true };
    }
  } catch (error) {
    console.error('Photo deletion error:', error);
    return { 
      success: false, 
      error: error.message || 'Failed to delete photo' 
    };
  }
};

/**
 * Creates a thumbnail from an image file
 * @param {File} file - The image file
 * @param {number} size - Thumbnail size (default: 150)
 * @returns {Promise<string>} - Thumbnail base64 string
 */
export const createThumbnail = (file, size = 150) => {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();

    canvas.width = size;
    canvas.height = size;

    img.onload = () => {
      // Draw image centered and scaled to fit
      const scale = Math.min(size / img.width, size / img.height);
      const scaledWidth = img.width * scale;
      const scaledHeight = img.height * scale;
      const x = (size - scaledWidth) / 2;
      const y = (size - scaledHeight) / 2;

      ctx.drawImage(img, x, y, scaledWidth, scaledHeight);
      
      const thumbnail = canvas.toDataURL('image/jpeg', 0.7);
      resolve(thumbnail);
    };

    img.onerror = () => {
      reject(new Error('Failed to create thumbnail'));
    };

    img.src = URL.createObjectURL(file);
  });
};

/**
 * Gets file size in human-readable format
 * @param {number} bytes - File size in bytes
 * @returns {string} - Human-readable size (e.g., "2.5 MB")
 */
export const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

// Export default object with all functions
export default {
  validateImage,
  compressImage,
  convertToBase64,
  generateUniqueFilename,
  getFileExtension,
  uploadPhoto,
  deletePhoto,
  createThumbnail,
  formatFileSize,
  CONFIG
};
