import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // Sign up
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  // Sign in
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Get user
  static User? get currentUser => client.auth.currentUser;

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Upload Avatar
  static Future<String> uploadAvatar(dynamic fileBytes, String extension) async {
    final userId = currentUser!.id;
    final path = '$userId/avatar.$extension';
    
    await client.storage.from('avatars').uploadBinary(
      path, 
      fileBytes, 
      fileOptions: FileOptions(upsert: true, contentType: 'image/$extension')
    );
    
    // Add a unique timestamp to force cache breaking for the network image
    final url = client.storage.from('avatars').getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // Upload Movement Image
  static Future<String> uploadMovementImage(dynamic fileBytes, String extension) async {
    final userId = currentUser!.id;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$userId/$fileName';
    
    await client.storage.from('movements').uploadBinary(
      path, 
      fileBytes, 
      fileOptions: FileOptions(upsert: true, contentType: 'image/$extension')
    );
    
    final url = client.storage.from('movements').getPublicUrl(path);
    return url;
  }

  // Update user avatar URL in metadata
  static Future<void> updateUserAvatar(String avatarUrl) async {
    await client.auth.updateUser(UserAttributes(
      data: {'avatar_url': avatarUrl},
    ));
  }

  // Update user display name
  static Future<void> updateUserName(String name) async {
    await client.auth.updateUser(UserAttributes(
      data: {'full_name': name},
    ));
  }
}

