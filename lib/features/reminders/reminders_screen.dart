import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reminder_model.dart';
import 'reminder_service.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _isLoading = true;
  List<Reminder> _reminders = [];
  String _searchQuery = "";
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rems = await ReminderService.getReminders();
      if (mounted) {
        setState(() {
          _reminders = rems;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Reminder rem) async {
    try {
      await ReminderService.deleteReminder(rem.id!);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
      }
    }
  }
  
  Future<void> _toggleCompletion(Reminder rem) async {
    try {
      await ReminderService.toggleCompletion(rem.id!, !rem.isCompleted);
      _loadData();
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CyberpunkScaffold(body: const Center(child: CircularProgressIndicator(color: DoryColors.primary)));
    }

    final filteredRems = _reminders.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (m.title.toLowerCase().contains(q)) || 
             (m.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    return CyberpunkScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Topbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: const Border(bottom: BorderSide(color: DoryColors.border)),
                color: DoryColors.bg.withOpacity(0.7),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: DoryColors.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text("Recordatorios.", style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 18, color: DoryColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tus Pagos y Alertas", style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.bold, color: DoryColors.text)),
                    const SizedBox(height: 8),
                    Text("Dory te avisará incluso si estás fuera del agua.", style: TextStyle(fontSize: 13, color: DoryColors.textMuted)),
                    const SizedBox(height: 16),
                    // Button to add reminder
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoryColors.surface2,
                          foregroundColor: DoryColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: DoryColors.primary.withOpacity(0.5)),
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReminderScreen()));
                          if (result == true) _loadData();
                        },
                        icon: const Icon(Icons.add_alert, size: 20),
                        label: const Text("Crear Recordatorio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Search Filter
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Buscar pago (Ej. Luz, Internet)",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: const Icon(Icons.search, color: DoryColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ""); }) 
                            : null,
                        filled: true,
                        fillColor: DoryColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reminders List
                    ...filteredRems.map((rem) => _buildReminderCard(rem)).toList(),
                    if (filteredRems.isEmpty && _reminders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text("🔍", style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text("No lo encuentro", style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.bold, color: DoryColors.primary)),
                            ],
                          )
                        ),
                      ),
                    if (_reminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text("🔔", style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text("Sin alarmas", style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.bold, color: DoryColors.primary)),
                              const SizedBox(height: 8),
                              const Text("No tienes recordatorios activos", style: TextStyle(color: Colors.white54)),
                            ],
                          )
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder rem) {
    return Dismissible(
      key: Key(rem.id ?? rem.dueDate.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: DoryColors.error.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _delete(rem);
      },
      child: GestureDetector(
        onTap: () async {
          // final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddReminderScreen(existingReminder: rem)));
          // if (result == true) _loadData();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rem.isCompleted ? DoryColors.surface.withOpacity(0.5) : DoryColors.surface,
            border: Border.all(color: rem.isCompleted ? Colors.transparent : DoryColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Checkbox(
                value: rem.isCompleted,
                onChanged: (_) => _toggleCompletion(rem),
                activeColor: DoryColors.primary,
                checkColor: DoryColors.bg,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem.title,
                      style: TextStyle(
                        color: DoryColors.text, 
                        fontWeight: FontWeight.w600,
                        decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
                      )
                    ),
                    if (rem.description != null && rem.description!.isNotEmpty)
                      Text(
                        rem.description!, 
                        style: TextStyle(
                          color: DoryColors.textMuted, 
                          fontSize: 12,
                          decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
                        )
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: rem.isCompleted ? DoryColors.textMuted : DoryColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          "${rem.dueDate.day}/${rem.dueDate.month}/${rem.dueDate.year} ${rem.dueDate.hour.toString().padLeft(2, '0')}:${rem.dueDate.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 11, color: rem.isCompleted ? DoryColors.textMuted : DoryColors.accent)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddReminderScreen(existingReminder: rem)));
                  if (result == true) _loadData();
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: DoryColors.error, size: 18),
                onPressed: () => _delete(rem),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
