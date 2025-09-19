class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's a valid phone number (10-15 digits)
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Please enter a valid phone number';
    }
    
    // Check if it contains only digits and optional + at start
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Rating validation
  static String? validateRating(int? value) {
    if (value == null) {
      return 'Rating is required';
    }
    
    if (value < 1 || value > 5) {
      return 'Rating must be between 1 and 5';
    }
    
    return null;
  }

  // Review validation
  static String? validateReview(String? value) {
    if (value == null) return null;
    
    if (value.length > 500) {
      return 'Review must be less than 500 characters';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return 'Date cannot be in the future';
    }
    
    // Check if date is not too far in the past (e.g., more than 1 year)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (value.isBefore(oneYearAgo)) {
      return 'Date cannot be more than 1 year ago';
    }
    
    return null;
  }

  // Age validation
  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Birth date is required';
    }
    
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid birth date';
    }
    
    return null;
  }

  // File size validation
  static String? validateFileSize(int fileSize, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    
    if (fileSize > maxSizeInBytes) {
      return 'File size must be less than ${maxSizeInMB}MB';
    }
    
    return null;
  }

  // Image file validation
  static String? validateImageFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'Image is required';
    }
    
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final extension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
    
    if (!allowedExtensions.contains(extension)) {
      return 'Please select a valid image file (JPG, PNG, or WEBP)';
    }
    
    return null;
  }

  // Credit card validation
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }
    
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Credit card number can only contain digits';
    }
    
    // Check length (13-19 digits)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Please enter a valid credit card number';
    }
    
    return null;
  }

  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'Please enter a valid CVV (3-4 digits)';
    }
    
    return null;
  }

  // Expiry date validation
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    // Check format MM/YY
    if (!RegExp(r'^\d{2}\/\d{2}$').hasMatch(value)) {
      return 'Please enter expiry date in MM/YY format';
    }
    
    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');
    
    if (month == null || year == null) {
      return 'Please enter a valid expiry date';
    }
    
    if (month < 1 || month > 12) {
      return 'Month must be between 01 and 12';
    }
    
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Credit card has expired';
    }
    
    return null;
  }

  // ZIP code validation
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'ZIP code is required';
    }
    
    // US ZIP code format (5 digits or 5+4 format)
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
      return 'Please enter a valid ZIP code';
    }
    
    return null;
  }

  // State validation
  static String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'State is required';
    }
    
    // Check if it's a valid US state abbreviation
    final validStates = [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    ];
    
    if (!validStates.contains(value.toUpperCase())) {
      return 'Please enter a valid state abbreviation';
    }
    
    return null;
  }

  // Generic length validation
  static String? validateLength(String? value, int minLength, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  // Multiple validation
  static String? validateMultiple(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }

  // Custom validation
  static String? validateCustom(String? value, bool Function(String) validator, String errorMessage) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (!validator(value)) {
      return errorMessage;
    }
    
    return null;
  }
}

