import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        return false;
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        biometricOnly: false,   // ✅ direct parameter now
      );

      return authenticated;
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }
}