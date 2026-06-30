import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase phone-number OTP verification.
///
/// Flow:
///   1. [sendCode] with a 10-digit Indian number → Firebase sends an SMS
///      (or, for numbers registered as test numbers in the Firebase console,
///      no SMS is sent and the fixed test code is accepted).
///   2. On `codeSent`, [onCodeSent] fires — move the UI to the OTP step.
///   3. [verify] the entered 6-digit code → signs the user in on success.
class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  /// Sends an OTP to `+91<phone>`.
  ///
  /// [onCodeSent] fires when the SMS has been dispatched (proceed to OTP entry).
  /// [onFailed] fires with a human-readable message on error.
  /// [onAutoVerified] fires if Android auto-retrieves and verifies the code
  /// without manual entry (the user is already signed in at that point).
  Future<void> sendCode(
    String phone, {
    required void Function() onCodeSent,
    required void Function(String message) onFailed,
    void Function()? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call();
        } catch (_) {/* fall back to manual entry */}
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification failed. Please try again.');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verifies the entered [smsCode] against the last sent OTP. Throws on
  /// failure (e.g. wrong code / expired session).
  Future<void> verify(String smsCode) async {
    final id = _verificationId;
    if (id == null) {
      throw Exception('Please request an OTP first.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  /// Human-readable message from a Firebase/phone-auth error.
  static String humanError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'Invalid OTP. Please check and try again.';
        case 'session-expired':
          return 'OTP expired. Please request a new one.';
        case 'invalid-phone-number':
          return 'Enter a valid phone number.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
      }
      return e.message ?? 'Verification failed.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
