import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient? _client;

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return _client!;
  }

  /// Initialize Supabase
  /// Simple initialization like PlasticMart - let Supabase handle everything!
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
      debug: kDebugMode,
    );

    _client = Supabase.instance.client;
    print('✅ Supabase client initialized');
  }

  /// Get auth instance
  static GoTrueClient get auth => client.auth;

  /// Get storage instance
  static SupabaseStorageClient get storage => client.storage;

  /// Get database instance
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Call RPC function
  static PostgrestFilterBuilder rpc(String functionName, {Map<String, dynamic>? params}) {
    return client.rpc(functionName, params: params);
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => auth.currentUser?.id;

  /// Get current user email
  static String? get currentUserEmail => auth.currentUser?.email;

  /// Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Check if session is valid and refresh if needed
  static Future<bool> ensureValidSession() async {
    try {
      final session = auth.currentSession;
      if (session == null) {
        print('ℹ️ No active session');
        return false;
      }

      // Check if token is about to expire (within 5 minutes)
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt - now;

        if (timeUntilExpiry < 300) {
          // Less than 5 minutes, try to refresh
          print('⏰ Token expiring soon, refreshing...');
          try {
            final response = await auth.refreshSession();
            if (response.session != null) {
              print('✅ Token refreshed successfully');
              return true;
            }
          } catch (e) {
            print('❌ Token refresh failed: $e');
            // If refresh fails, sign out to clear corrupted session
            await signOut();
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('❌ Session check failed: $e');
      return false;
    }
  }

  /// Force clear all session data (use when corrupted)
  static Future<void> clearCorruptedSession() async {
    try {
      print('🔥 Clearing corrupted session...');
      await auth.signOut();
      // Also clear any local storage
      await Supabase.instance.dispose();
      print('✅ Session cleared');
    } catch (e) {
      print('⚠️ Error clearing session: $e');
    }
  }

  /// Dispose (for cleanup)
  static Future<void> dispose() async {
    _client = null;
  }
}
