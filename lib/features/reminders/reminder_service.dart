import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import 'reminder_model.dart';

class ReminderService {
  static final _client = Supabase.instance.client;

  static Future<List<Reminder>> getReminders() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    
    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', user.id)
        .order('due_date', ascending: true);
        
    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  static Future<Reminder> addReminder(Reminder reminder) async {
    final response = await _client.from('reminders').insert(reminder.toJson()).select().single();
    return Reminder.fromJson(response);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) return;
    await _client.from('reminders').update(reminder.toJson()).eq('id', reminder.id!);
  }

  static Future<void> deleteReminder(String id) async {
    await _client.from('reminders').delete().eq('id', id);
  }

  static Future<void> toggleCompletion(String id, bool isCompleted) async {
    await _client.from('reminders').update({'is_completed': isCompleted}).eq('id', id);
  }
}
