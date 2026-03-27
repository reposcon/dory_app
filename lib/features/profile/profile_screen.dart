import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/services/supabase_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      final meta = SupabaseService.currentUser?.userMetadata;
      _avatarUrl = meta?['avatar_url'];
      _fullName = meta?['full_name'];
      if (_fullName != null) _nameCtrl.text = _fullName!;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last;
        final publicUrl = await SupabaseService.uploadAvatar(bytes, ext);
        await SupabaseService.updateUserAvatar(publicUrl);
        _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar actualizado con éxito')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir avatar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateUserName(name);
      _loadUserData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado con éxito')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar nombre: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final pass = _passCtrl.text.trim();
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.updatePassword(pass);
      _passCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada con éxito')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar contraseña: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final initials = (user?.email?.isNotEmpty == true) ? user!.email!.substring(0, 2).toUpperCase() : 'US';

    return CyberpunkScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: Text("Perfil y Ajustes", style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 18, color: DoryColors.primary)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DoryColors.primary, width: 3),
                          boxShadow: [BoxShadow(color: DoryColors.primary.withOpacity(0.5), blurRadius: 20)],
                          image: _avatarUrl != null 
                            ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                            : null,
                          gradient: _avatarUrl == null ? const LinearGradient(colors: [DoryColors.primary, Color(0xFF0077ff)]) : null,
                        ),
                        alignment: _avatarUrl == null ? Alignment.center : null,
                        child: _avatarUrl == null 
                          ? Text(initials, style: const TextStyle(color: DoryColors.bg, fontWeight: FontWeight.bold, fontSize: 32))
                          : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: DoryColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: DoryColors.bg),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(_fullName ?? user?.email ?? 'Usuario', style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.bold, color: DoryColors.text)),
                if (_fullName != null) 
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 40),
                
                // Section: Datos Personales
                const Align(alignment: Alignment.centerLeft, child: Text("DATOS PERSONALES", style: TextStyle(color: DoryColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tu Nombre Real',
                    labelStyle: TextStyle(color: Colors.white54),
                    icon: Icon(Icons.person_outline, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator(color: DoryColors.primary)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _updateName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoryColors.surface2,
                        foregroundColor: DoryColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: DoryColors.primary.withOpacity(0.3))),
                      ),
                      child: const Text('Actualizar Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Section: Security
                const Align(alignment: Alignment.centerLeft, child: Text("SEGURIDAD", style: TextStyle(color: DoryColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: TextStyle(color: Colors.white54),
                    icon: Icon(Icons.lock_outline, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator(color: DoryColors.primary)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoryColors.surface2,
                        foregroundColor: DoryColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: DoryColors.primary.withOpacity(0.3))),
                      ),
                      child: const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Section: Danger Zone
                const Align(alignment: Alignment.centerLeft, child: Text("ZONA PELIGROSA", style: TextStyle(color: DoryColors.error, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close Profile screen
                      SupabaseService.signOut();
                    },
                    icon: const Icon(Icons.logout, color: DoryColors.error),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DoryColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    label: const Text('Cerrar Sesión Segura', style: TextStyle(color: DoryColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
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
