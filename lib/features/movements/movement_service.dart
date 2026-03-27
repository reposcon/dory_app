import 'package:supabase_flutter/supabase_flutter.dart';
import 'movement_model.dart';
import '../../core/services/supabase_service.dart';

class MovementService {
  static final _client = Supabase.instance.client;

  static Future<List<Movement>> getMovements() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    
    final response = await _client
        .from('movements')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Movement.fromJson(e)).toList();
  }

  static Future<void> addMovement(Movement movement) async {
    await _client.from('movements').insert(movement.toJson());
  }

  static Future<void> deleteMovement(String id) async {
    await _client.from('movements').delete().eq('id', id);
  }

  static Future<void> updateMovement(Movement movement) async {
    await _client.from('movements').update(movement.toJson()).eq('id', movement.id!);
  }
}
