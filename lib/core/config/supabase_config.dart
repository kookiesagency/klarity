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
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
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

  /// Dispose (for cleanup)
  static Future<void> dispose() async {
    _client = null;
  }
}
