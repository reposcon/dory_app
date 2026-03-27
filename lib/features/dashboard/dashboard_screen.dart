import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';
import '../movements/movement_model.dart';
import '../movements/movement_service.dart';
import '../movements/add_movement_screen.dart';
import '../tutorial/tutorial_screen.dart';
import '../profile/profile_screen.dart';
import 'dory_chat_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Movement> _movements = [];
  double _balance = 0;
  double _incomesThisMonth = 0;
  double _expensesThisMonth = 0;
  bool _obscureAmounts = false;
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
      final movs = await MovementService.getMovements();
      double balance = 0;
      double incMonth = 0;
      double expMonth = 0;
      
      final now = DateTime.now();

      for (var m in movs) {
        if (m.type == 'ingreso') balance += m.amount;
        if (m.type == 'egreso') balance -= m.amount;

        bool isThisMonth = m.createdAt?.year == now.year && m.createdAt?.month == now.month;
        if (isThisMonth) {
          if (m.type == 'ingreso') incMonth += m.amount;
          if (m.type == 'egreso') expMonth += m.amount;
        }
      }

      if (mounted) {
        setState(() {
          _movements = movs;
          _balance = balance;
          _incomesThisMonth = incMonth;
          _expensesThisMonth = expMonth;
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

  Future<void> _deleteMovement(Movement mov) async {
    try {
      await MovementService.deleteMovement(mov.id!);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CyberpunkScaffold(body: const Center(child: CircularProgressIndicator(color: DoryColors.primary)));
    }

    final user = SupabaseService.client.auth.currentUser;
    final userEmail = user?.email ?? 'Usuario';
    final fullName = user?.userMetadata?['full_name'];
    final displayFirstName = fullName != null && fullName.isNotEmpty ? fullName.split(' ')[0] : 'de nuevo';
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase()
        : (userEmail.isNotEmpty ? userEmail.substring(0, 2).toUpperCase() : 'US');
    final avatarUrl = user?.userMetadata?['avatar_url'];

    String badge = "🐟 Pececillo curioso";
    if (_balance > 50000) badge = "🦈 Tiburón Financiero";
    else if (_balance > 10000) badge = "🐬 Buceador Experto";
    else if (_balance > 0) badge = "🐟 Pececillo curioso";
    else if (_balance <= -10000) badge = "🦀 Submarino en apuros";
    else if (_balance < 0) badge = "⚓ Naufrago";

    final filteredMovs = _movements.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (m.category.toLowerCase().contains(q)) || 
             (m.description?.toLowerCase().contains(q) ?? false) ||
             (m.amount.toString().contains(q));
    }).toList();

    double totalInOut = _incomesThisMonth + _expensesThisMonth;
    double incomePercent = totalInOut > 0 ? _incomesThisMonth / totalInOut : 0.5;

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
                      Text("Dory.", style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 18, color: DoryColors.primary)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_obscureAmounts ? Icons.visibility_off : Icons.visibility, color: DoryColors.primary),
                    onPressed: () => setState(() => _obscureAmounts = !_obscureAmounts),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: DoryColors.primary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()));
                    },
                  ),
                  const SizedBox(width: 8),
                    GestureDetector(
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DoryColors.primary, width: 2),
                          gradient: avatarUrl == null ? const LinearGradient(colors: [DoryColors.primary, Color(0xFF0077ff)]) : null,
                          boxShadow: [BoxShadow(color: DoryColors.primary.withOpacity(0.3), blurRadius: 12)],
                          image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                        ),
                        alignment: avatarUrl == null ? Alignment.center : null,
                        child: avatarUrl == null ? Text(initials, style: const TextStyle(color: DoryColors.bg, fontWeight: FontWeight.bold, fontSize: 13)) : null,
                      ),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        if (mounted) setState((){});
                      },
                    )
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Hola, $displayFirstName 👋", style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.bold, color: DoryColors.text)),
                            const Spacer(),
                            if (!_obscureAmounts && _movements.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DoryColors.surface.withOpacity(0.5), 
                                  borderRadius: BorderRadius.circular(12), 
                                  border: Border.all(color: DoryColors.primary)
                                ),
                                child: Text(badge, style: const TextStyle(fontSize: 12, color: DoryColors.primary, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                        Text("Resumen financiero", style: TextStyle(fontSize: 13, color: DoryColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMovementScreen()));
                          if (result == true) _loadData();
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text("Agregar un nuevo movimiento", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard("Saldo disponible", _obscureAmounts ? "****" : "\$${_balance.toStringAsFixed(0)}", _balance >= 0, "💳"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard("Gastos del mes", _obscureAmounts ? "****" : "\$${_expensesThisMonth.toStringAsFixed(0)}", false, "📉", onTap: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMovementScreen(initialType: 'egreso')));
                            if (result == true) _loadData();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Financial Health Bar
                    Text("Salud mensual", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DoryColors.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: DoryColors.error),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: incomePercent,
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: DoryColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Ingresos", style: TextStyle(fontSize: 11, color: DoryColors.primary)),
                        Text("Gastos", style: TextStyle(fontSize: 11, color: DoryColors.error)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Chat Panel Integration
                    Text("Chat con Dory", style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: DoryColors.text)),
                    const SizedBox(height: 12),
                    DoryChatPanel(
                      incomes: _incomesThisMonth, 
                      expenses: _expensesThisMonth, 
                      recentMovements: _movements.take(5).map((e) => e.toJson()).toList()
                    ),
                    const SizedBox(height: 28),

                    // Dory's Memory Search
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "¿Qué quieres que Dory recuerde?",
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

                    // Recent Movements
                    Text("Movimientos recientes", style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: DoryColors.text)),
                    const SizedBox(height: 12),
                    ...filteredMovs.map((mov) => _buildMovementCard(mov)).toList(),
                    if (filteredMovs.isEmpty && _movements.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text("🐠", style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text("Agua turbia...", style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.bold, color: DoryColors.primary)),
                              const SizedBox(height: 8),
                              const Text("Dory no recuerda ese movimiento", style: TextStyle(color: Colors.white54)),
                            ],
                          )
                        ),
                      ),
                    if (_movements.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Text("🌊", style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text("El océano está en calma", style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.bold, color: DoryColors.primary)),
                              const SizedBox(height: 8),
                              const Text("No tienes movimientos registrados", style: TextStyle(color: Colors.white54)),
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

  Widget _buildStatCard(String label, String value, bool isPositive, String icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DoryColors.surface,
        border: Border.all(color: DoryColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DoryColors.textMuted)),
              Text(icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.bold, color: isPositive ? DoryColors.primary : DoryColors.error)),
        ],
      ),
    ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl, 
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200, 
                    child: Center(child: CircularProgressIndicator(color: DoryColors.primary))
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(Movement mov) {
    final isIncome = mov.type == 'ingreso';
    final color = isIncome ? DoryColors.primary : DoryColors.error;
    
    return Dismissible(
      key: Key(mov.id ?? mov.createdAt.toString()),
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
        _deleteMovement(mov);
      },
      child: GestureDetector(
        onTap: () {
          if (mov.imageUrl != null) {
            _showImageDialog(mov.imageUrl!);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DoryColors.surface,
            border: Border.all(color: DoryColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(mov.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${mov.category} - ${isIncome ? 'Ingreso' : 'Egreso'}", style: const TextStyle(color: DoryColors.text, fontWeight: FontWeight.w500)),
                    if (mov.description != null && mov.description!.isNotEmpty)
                      Text(mov.description!, style: TextStyle(color: DoryColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (mov.imageUrl != null)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.image, color: Colors.white54, size: 20),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _obscureAmounts ? "****" : "${isIncome ? '+' : '-'}\$${mov.amount.toStringAsFixed(0)}",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMovementScreen(existingMovement: mov)));
                          if (result == true) _loadData();
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: DoryColors.error, size: 18),
                        onPressed: () => _deleteMovement(mov),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

