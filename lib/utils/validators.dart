import 'package:flutter/widgets.dart';
import '../services/firestore_service.dart';


class Validators {
  final _firestoreService = FirestoreService();



  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }


  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }


  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }


 static String? dateOfBirthValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of Birth is required';
    }
    try {
      final dob = DateTime.parse(value);
      final today = DateTime.now();
      final age = today.year - dob.year - ((today.month < dob.month || (today.month == dob.month && today.day < dob.day)) ? 1 : 0);
      if (age < 18) {
        return 'You must be at least 18 years old to vote';
      }
    } catch (e) {
      return 'Please enter a valid date (DD-MM-YYYY): ${e}';
    }
    return null;
  }


  static String? validateVoterID(String? value) {
    if (value == null || value.isEmpty) {
      return 'Voter ID is required';
    }
    final cleanValue = value.replaceAll(' ', '');
    if (cleanValue.length != 10) {
      return 'Voter ID must be 10 characters';
    }
    final voterIdRegex = RegExp(r'^[A-Z]{3}[0-9]{7}$');
    if (!voterIdRegex.hasMatch(value)) {
      return 'Please enter a valid Voter ID (e.g., ABC1234567) first 3 capital letters followed by 7 digits';
    }


    return null;
  }


  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    final cleanValue = value.replaceAll(' ', '');
    if (cleanValue.length != 12) {
      return 'Aadhaar number must be 12 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
      return 'Aadhaar number can only contain digits';
    }
    if (cleanValue.startsWith('0') || cleanValue.startsWith('1')) {
      return 'Invalid Aadhaar number';
    }
    return null;
  }


  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }


  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }


  static String? addressValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    if (value.length > 100) {
      return 'Address must be less than 100 characters';
    }
    return null;
  }
 

  static String? validateConstituency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Constituency is required';
    }
    return null;
  }




  static String? validateElectionTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Election title is required';
    }
    if (value.length < 5) {
      return 'Title must be at least 5 characters';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  static String? validateCandidateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Candidate name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validatePartyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Party name is required';
    }
    return null;
  }
}
