import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/colors.dart';
import '../../core/services/supabase_service.dart';
import 'reminder_model.dart';
import 'reminder_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? existingReminder;
  const AddReminderScreen({Key? key, this.existingReminder}) : super(key: key);

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleCtrl.text = widget.existingReminder!.title;
      _descCtrl.text = widget.existingReminder!.description ?? '';
      _selectedDate = widget.existingReminder!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingReminder!.dueDate);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DoryColors.primary,
              onPrimary: DoryColors.bg,
              surface: DoryColors.surface,
              onSurface: DoryColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DoryColors.primary,
              onPrimary: DoryColors.bg,
              surface: DoryColors.surface,
              onSurface: DoryColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El título es obligatorio.')));
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (finalDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha y hora deben ser en el futuro.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) throw Exception("Usuario no autenticado");

      final rem = Reminder(
        id: widget.existingReminder?.id,
        userId: widget.existingReminder?.userId ?? uid,
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dueDate: finalDateTime,
        isCompleted: widget.existingReminder?.isCompleted ?? false,
        createdAt: widget.existingReminder?.createdAt,
      );

      Reminder savedReminder;
      if (widget.existingReminder != null) {
        await ReminderService.updateReminder(rem);
        savedReminder = rem;
      } else {
        savedReminder = await ReminderService.addReminder(rem);
      }

      // Schedule local notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: savedReminder.id.hashCode,
          channelKey: 'dory_alerts',
          title: '🚨 Recordatorio Dory: $title',
          body: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : '¡Es hora de prestar atención a este pago o evento!',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: finalDateTime),
      );

      if (mounted) {
        final act = widget.existingReminder != null ? 'actualizado' : 'creado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recordatorio $act con éxito.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberpunkScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.existingReminder != null ? 'Editar Recordatorio' : 'Nuevo Recordatorio', style: const TextStyle(fontSize: 18)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                    labelText: 'Título del Pago (Ej: Luz, Netflix)',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Detalles (Opcional)',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                
                Text('Fecha y Hora del Aviso', style: TextStyle(color: DoryColors.textMuted, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: DoryColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DoryColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, color: DoryColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: DoryColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DoryColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, color: DoryColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(_selectedTime.format(context), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: DoryColors.primary, strokeWidth: 2))
                      : const Text('GUARDAR ALARMA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                )
              ],
            ),
          )
        )
      )
    );
  }
}
