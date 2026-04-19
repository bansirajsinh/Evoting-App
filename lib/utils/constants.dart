import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF66BB6A);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppDimens {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
}

class FirestoreCollections {
  static const String users = 'users';
  static const String admins = 'admins';
  static const String elections = 'elections';
  static const String candidates = 'candidates';
  static const String votes = 'votes';
  static const String voterProfiles = 'voter_profiles';
}

class BlockchainConfig {
  static const String ganacheUrl = 'http://127.0.0.1:7545';
  static const String contractAddress = '0x9d7834C376B2b722c5693af588C3e7a03Ea8e44D';
  static const int chainId = 1337;
}

class AppStrings {
  static const String appName = 'E-Vote';
  static const String tagline = 'Secure Blockchain Voting';
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to your account';
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join our secure voting platform';
  static const String otpTitle = 'Verify Phone';
  static const String otpSubtitle = 'Enter the OTP sent to your phone';
  static const String homeTitle = 'Dashboard';
  static const String electionsTitle = 'Elections';
  static const String votingTitle = 'Cast Your Vote';
  static const String historyTitle = 'Voting History';
  static const String profileTitle = 'Profile';
  static const String adminDashboard = 'Admin Dashboard';
  static const String manageElections = 'Manage Elections';
  static const String manageCandidates = 'Manage Candidates';
  static const String manageVoters = 'Manage Voters';
  static const String viewResults = 'View Results';
}

class UserRoles {
  static const String voter = 'voter';
  static const String admin = 'admin';
}
