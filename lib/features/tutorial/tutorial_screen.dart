import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CyberpunkScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Saltar", style: TextStyle(color: Colors.white54)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildTutorialPage(
                    title: "El Arrecife",
                    description: "Aquí verás tu saldo histórico y los movimientos del mes. ¡Mantén esos números azules!",
                    icon: "🌊",
                  ),
                  _buildTutorialPage(
                    title: "Registra Movimientos",
                    description: "Toca 'Ingresos', 'Gastos', o el botón superior de 'Nuevo movimiento' para crear registros.",
                    icon: "💳",
                  ),
                  _buildTutorialPage(
                    title: "Dory te ayuda",
                    description: "Chatea interactuando con Dory. Es un poco olvidadiza pero siempre te dará excelentes consejos sobre tus movimientos.",
                    icon: "🐟",
                  ),
                  _buildTutorialPage(
                    title: "Tu Perfil",
                    description: "Toca tu imagen en la esquina superior para gestionar tu cuenta. Desde allí puedes cambiar tu foto, tu contraseña o cerrar sesión.",
                    icon: "👤",
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => _buildDot(i)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 3) {
                      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoryColors.primary,
                    foregroundColor: DoryColors.bg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_currentPage < 3 ? 'Siguiente' : '¡Entendido!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? DoryColors.primary : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTutorialPage({required String title, required String description, required String icon}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DoryColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: DoryColors.border),
              boxShadow: [BoxShadow(color: DoryColors.primary.withOpacity(0.2), blurRadius: 40)],
            ),
            child: Text(icon, style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 48),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold, color: DoryColors.primary)),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: DoryColors.textMuted, height: 1.5)),
        ],
      ),
    );
  }
}
