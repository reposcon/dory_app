import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/services/gemini_service.dart';
import 'package:google_fonts/google_fonts.dart';

class DoryChatPanel extends StatefulWidget {
  final double incomes;
  final double expenses;
  final List<Map<String, dynamic>> recentMovements;

  const DoryChatPanel({
    Key? key,
    required this.incomes,
    required this.expenses,
    required this.recentMovements,
  }) : super(key: key);

  @override
  State<DoryChatPanel> createState() => _DoryChatPanelState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _DoryChatPanelState extends State<DoryChatPanel> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _getInitialAdvice();
  }

  Future<void> _getInitialAdvice() async {
    setState(() => _isTyping = true);
    final advice = await GeminiService.getDorysAdvice(
      incomes: widget.incomes,
      expenses: widget.expenses,
    ); // No pasamos recentMovements para pedir el advice estático
    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: advice, isUser: false));
        _isTyping = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _msgCtrl.clear();

    final prompt = "El usuario acaba de decir: '\$text'. Responde en menos de 2 oraciones, de acuerdo con tu personalidad actual.";
    
    final response = await GeminiService.getDorysAdvice(
      incomes: widget.incomes,
      expenses: widget.expenses,
      recentMovements: [
        {"type": "user_msg", "amount": 0, "category": "chat", "emoji": "💬", "description": prompt}
      ],
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DoryColors.bg.withOpacity(0.5),
        border: Border.all(color: DoryColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      height: 400,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DoryColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [DoryColors.primary, Color(0xFF0077cc)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: DoryColors.border),
                    boxShadow: [
                      BoxShadow(color: DoryColors.primary.withOpacity(0.25), blurRadius: 20)
                    ]
                  ),
                  child: const Center(child: Text("🐟", style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dory", style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 16, color: DoryColors.text)),
                    Text("Tu asistente financiera · En línea", style: TextStyle(fontSize: 11, color: DoryColors.textMuted)),
                  ],
                )
              ],
            ),
          ),
          // Msgs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("Dory está escribiendo...", style: TextStyle(fontSize: 12, color: Colors.white54)),
                    ),
                  );
                }
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: DoryColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: DoryColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DoryColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(fontSize: 13, color: DoryColors.text),
                      decoration: const InputDecoration(
                        hintText: "Escríbele a Dory...",
                        hintStyle: TextStyle(color: DoryColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: DoryColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: DoryColors.bg),
                    onPressed: () => _sendMessage(_msgCtrl.text),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DoryColors.primary.withOpacity(0.25), const Color(0xFF0078C8).withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: DoryColors.primary.withOpacity(0.25)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(msg.text, style: const TextStyle(fontSize: 13, color: DoryColors.text)),
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: DoryColors.accent,
              child: Text("JD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DoryColors.bg)),
            )
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: DoryColors.primary,
              child: Text("🐟", style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: DoryColors.surface2,
                  border: Border.all(color: DoryColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text(msg.text, style: const TextStyle(fontSize: 13, color: DoryColors.text)),
              ),
            ),
          ],
        ),
      );
    }
  }
}
