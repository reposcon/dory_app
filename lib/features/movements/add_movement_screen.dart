import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/colors.dart';
import '../../core/services/supabase_service.dart';
import 'movement_model.dart';
import 'movement_service.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:image_picker/image_picker.dart';

class AddMovementScreen extends StatefulWidget {
  final String? initialType;
  final Movement? existingMovement;
  const AddMovementScreen({Key? key, this.initialType, this.existingMovement}) : super(key: key);

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Comida');
  late String _type;
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMovement != null) {
      _type = widget.existingMovement!.type;
      _amountCtrl.text = widget.existingMovement!.amount.toStringAsFixed(0);
      _descCtrl.text = widget.existingMovement!.description ?? '';
      _categoryCtrl.text = widget.existingMovement!.category;
    } else {
      _type = widget.initialType ?? 'egreso';
    }
  }

  final Map<String, String> _knownCategories = {
    'Sueldo': '🏦',
    'Venta': '🚀',
    'Moto': '⛽',
    'Casa': '🏠',
    'Comida': '🍕',
    'Antojo': '🐜',
    'Préstamo': '🛟',
    'Otro': '📦',
  };

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  void _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    if (_type == 'egreso' && amount > 1000) {
      try {
        await Haptics.vibrate(HapticsType.heavy);
        await Future.delayed(const Duration(milliseconds: 200));
        await Haptics.vibrate(HapticsType.heavy);
      } catch (e) {
        // Haptics not supported on Windows, graceful fail
      }
    } else {
      try { await Haptics.vibrate(HapticsType.light); } catch (_) {}
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.name.split('.').last;
        imageUrl = await SupabaseService.uploadMovementImage(bytes, ext);
      }

      final uid = SupabaseService.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
      final customCategory = _categoryCtrl.text.trim().isEmpty ? 'Otro' : _categoryCtrl.text.trim();
      // Try to find matching known emoji, otherwise default to a generic memo emoji
      String finalEmoji = '📝';
      _knownCategories.forEach((key, val) {
        if (key.toLowerCase() == customCategory.toLowerCase()) finalEmoji = val;
      });

      final mov = Movement(
        id: widget.existingMovement?.id,
        userId: widget.existingMovement?.userId ?? uid,
        amount: amount,
        type: _type,
        category: customCategory,
        emoji: finalEmoji,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        imageUrl: imageUrl ?? widget.existingMovement?.imageUrl,
        createdAt: widget.existingMovement?.createdAt,
      );

      if (uid != '00000000-0000-0000-0000-000000000000') {
        if (widget.existingMovement != null) {
          await MovementService.updateMovement(mov);
        } else {
          await MovementService.addMovement(mov);
        }
      }
      if (mounted) {
        final action = widget.existingMovement != null ? 'actualizado' : 'agregado';
        final tipo = _type == 'ingreso' ? 'ingreso' : 'egreso';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Nuevo $tipo $action con éxito!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando en Supabase: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CyberpunkScaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: _type,
                  dropdownColor: DoryColors.bg,
                  items: const [
                    DropdownMenuItem(value: 'ingreso', child: Text('Ingreso (Tesoro)', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'egreso', child: Text('Egreso (Naufragio)', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 32),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(color: Colors.white, fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Categoría (Ej: Comida, Sueldo, Viaje)',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Quick Category Chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Sugerencias:", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _knownCategories.keys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final catName = _knownCategories.keys.elementAt(index);
                      final emoji = _knownCategories[catName];
                      final isSelected = _categoryCtrl.text.trim().toLowerCase() == catName.toLowerCase();
                      
                      return GestureDetector(
                        onTap: () => setState(() => _categoryCtrl.text = catName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? DoryColors.primary : DoryColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? DoryColors.primary : DoryColors.border),
                          ),
                          child: Center(
                            child: Text("$emoji $catName", style: TextStyle(
                              color: isSelected ? DoryColors.bg : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _selectedImage != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: DoryColors.primary, size: 28),
                              SizedBox(width: 8),
                              Text('Foto adjuntada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, color: Colors.white54),
                              SizedBox(height: 8),
                              Text('Adjuntar recibo o foto', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _save,
                    child: _isUploading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: DoryColors.primary, strokeWidth: 2))
                      : const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
