import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

const double _kPayBreakpoint = 700;

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments      = [];
  List<Payment> _pending       = [];
  List<Payment> _completed     = [];
  bool          _isLoading     = true;
  String        _filterTipo    = 'todos';
  User?         _currentUser;

  double _totalPendiente  = 0;
  double _totalCompletado = 0;

  final _fmt = NumberFormat('#,##0.00', 'es');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userR     = await AuthService.getCurrentUser();
    final paymentsR = await PaymentService.getAll();
    final summaryR  = await PaymentService.getSummary();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userR['success'])     _currentUser = userR['user'];
        if (paymentsR['success']) {
          _payments  = List<Payment>.from(paymentsR['payments']);
          _pending   = _payments.where((p) => p.estadoPago == PaymentStatus.pendiente).toList();
          _completed = _payments.where((p) => p.estadoPago == PaymentStatus.completado).toList();
        }
        if (summaryR['success']) {
          final data       = summaryR['data'];
          _totalPendiente  = double.tryParse(data['total_pendiente']?.toString()  ?? '0') ?? 0;
          _totalCompletado = double.tryParse(data['total_completado']?.toString() ?? '0') ?? 0;
        }
      });
    }
  }

  List<Payment> get _filteredCompleted {
    if (_filterTipo == 'todos') return _completed;
    return _completed.where((p) => p.tipo.name == _filterTipo).toList();
  }

  Future<void> _showPaymentModal(Payment payment) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentModal(
        payment: payment,
        onPaid: (metodoPago) async {
          Navigator.pop(context);
          await _processPayment(payment, metodoPago);
        },
      ),
    );
  }

  Future<void> _processPayment(Payment payment, String metodoPago) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5))));
    await Future.delayed(const Duration(seconds: 2));
    final r = await PaymentService.pay(payment.id!, metodoPago);
    if (mounted) Navigator.pop(context);
    if (mounted) {
      if (r['success'] == true) {
        await showDialog(
          context: context,
          builder: (_) => _PaymentSuccessDialog(payment: payment, metodoPago: metodoPago));
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['message'] ?? 'Error al procesar pago'),
          backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    final isNarrow = MediaQuery.of(context).size.width < _kPayBreakpoint;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(isNarrow),
          const SizedBox(height: 24),
          if (_pending.isNotEmpty) ...[
            _buildPendingSection(),
            const SizedBox(height: 24),
          ],
          _buildHistorialSection(isNarrow),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pagos y Facturación', style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 4),
          Text(
            'Administra tus servicios médicos, métodos de pago y descarga tus comprobantes fiscales.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
        if (_pending.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _showPaymentModal(_pending.first),
            icon: const Icon(Icons.payment_outlined, size: 18),
            label: const Text('Pagar Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isNarrow) {
    final cards = [
      _summaryCard('Total Pendiente', '\$${_fmt.format(_totalPendiente)}',
          Icons.pending_actions_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
      _summaryCard('Total Pagado', '\$${_fmt.format(_totalCompletado)}',
          Icons.check_circle_outline, const Color(0xFF10B981), const Color(0xFFD1FAE5)),
      _summaryCard('Pagos Pendientes', '${_pending.length}',
          Icons.receipt_outlined, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
      _summaryCard('Pagos Completados', '${_completed.length}',
          Icons.done_all_outlined, const Color(0xFF4F46E5), const Color(0xFFEDE9FE)),
    ];

    if (isNarrow) {
      return Column(children: [
        Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
      ]);
    }

    return Row(children: [
      Expanded(child: cards[0]), const SizedBox(width: 16),
      Expanded(child: cards[1]), const SizedBox(width: 16),
      Expanded(child: cards[2]), const SizedBox(width: 16),
      Expanded(child: cards[3]),
    ]);
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ])),
      ]),
    );
  }

  Widget _buildPendingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pending_actions_outlined, color: Color(0xFF1A1A7A), size: 20),
          const SizedBox(width: 8),
          const Text('Pagos Pendientes', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
            child: Text('${_pending.length} pendiente(s)',
              style: const TextStyle(
                color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        ..._pending.map((p) => _pendingCard(p)),
      ]),
    );
  }

  Widget _pendingCard(Payment p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _tipoColor(p.tipo).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(_tipoIcon(p.tipo), color: _tipoColor(p.tipo), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.concepto, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 4),
          if (p.fechaVencimiento != null)
            Text('Vence: ${DateFormat('d MMM', 'es').format(p.fechaVencimiento!)}',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${_fmt.format(p.monto)}', style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () => _showPaymentModal(p),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero),
            child: const Text('Pagar', style: TextStyle(fontSize: 12))),
        ]),
      ]),
    );
  }

  Widget _buildHistorialSection(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header con filtros — Wrap para que no haga overflow
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Row(children: [
            Icon(Icons.history_outlined, color: Color(0xFF1A1A7A), size: 20),
            SizedBox(width: 8),
            Text('Historial de Transacciones', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
          ]),
          _filterChip('Todos',     'todos'),
          _filterChip('Consultas', 'consulta'),
          _filterChip('Estudios',  'estudio'),
          _filterChip('Seguros',   'seguro'),
        ]),
        const SizedBox(height: 16),

        // Tabla con scroll horizontal
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width -
                  (isNarrow ? 56 : 220 + 56)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const SizedBox(width: 200, child: _ThPay('CONCEPTO')),
                  const SizedBox(width: 130, child: _ThPay('FECHA')),
                  const SizedBox(width: 120, child: _ThPay('ESTADO')),
                  const SizedBox(width: 130, child: _ThPay('MONTO')),
                  const SizedBox(width: 90,  child: _ThPay('ACCIÓN')),
                ]),
              ),
              const SizedBox(height: 8),

              _filteredCompleted.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Column(children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('Sin transacciones completadas',
                          style: TextStyle(color: Colors.grey[400])),
                      ])))
                  : Column(children: _filteredCompleted.asMap().entries
                      .map((e) => _historialRow(e.value, e.key.isOdd)).toList()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _historialRow(Payment p, bool shaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: shaded ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        SizedBox(width: 200, child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tipoColor(p.tipo).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(_tipoIcon(p.tipo), color: _tipoColor(p.tipo), size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(p.concepto, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A7A)),
            overflow: TextOverflow.ellipsis)),
        ])),
        SizedBox(width: 130, child: Text(
          p.fechaPago != null
              ? DateFormat('dd MMM, yyyy', 'es').format(p.fechaPago!) : '—',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        SizedBox(width: 120, child: _estadoBadge(p.estadoPago)),
        SizedBox(width: 130, child: Text('\$${_fmt.format(p.monto)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A)))),
        SizedBox(width: 90, child: TextButton.icon(
          onPressed: () => _showFactura(p),
          icon: const Icon(Icons.receipt_outlined, size: 14),
          label: const Text('Factura', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5), padding: EdgeInsets.zero))),
      ]),
    );
  }

  void _showFactura(Payment p) {
    showDialog(context: context, builder: (_) => _FacturaDialog(payment: p));
  }

  Widget _filterChip(String label, String value) {
    final active = _filterTipo == value;
    return GestureDetector(
      onTap: () => setState(() => _filterTipo = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A237E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : Colors.grey[600],
          fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _estadoBadge(PaymentStatus status) {
    final color = Color(int.parse('0x${status.color}'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Color _tipoColor(PaymentTipo tipo) {
    switch (tipo) {
      case PaymentTipo.consulta:     return const Color(0xFF4F46E5);
      case PaymentTipo.estudio:      return const Color(0xFF06B6D4);
      case PaymentTipo.seguro:       return const Color(0xFF10B981);
      case PaymentTipo.vacuna:       return const Color(0xFFF59E0B);
      case PaymentTipo.psicoterapia: return const Color(0xFF7C3AED);
      case PaymentTipo.otro:         return Colors.grey;
    }
  }

  IconData _tipoIcon(PaymentTipo tipo) {
    switch (tipo) {
      case PaymentTipo.consulta:     return Icons.medical_services_outlined;
      case PaymentTipo.estudio:      return Icons.science_outlined;
      case PaymentTipo.seguro:       return Icons.shield_outlined;
      case PaymentTipo.vacuna:       return Icons.vaccines_outlined;
      case PaymentTipo.psicoterapia: return Icons.psychology_outlined;
      case PaymentTipo.otro:         return Icons.receipt_outlined;
    }
  }
}

class _ThPay extends StatelessWidget {
  final String text;
  const _ThPay(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.bold,
    color: Color(0xFF4F46E5), letterSpacing: 0.5));
}

// ── Modal de pago simulado (sin cambios de lógica)
class _PaymentModal extends StatefulWidget {
  final Payment    payment;
  final Function(String) onPaid;
  const _PaymentModal({required this.payment, required this.onPaid});
  @override
  State<_PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<_PaymentModal> {
  String _metodoPago = 'tarjeta_credito';
  final _fmt = NumberFormat('#,##0.00', 'es');
  final _cardNumberCtrl = TextEditingController(text: '4242 4242 4242 4242');
  final _cardNameCtrl   = TextEditingController(text: 'TITULAR DE LA TARJETA');
  final _cardExpCtrl    = TextEditingController(text: '12/28');
  final _cardCvvCtrl    = TextEditingController(text: '123');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.payment_outlined, color: Color(0xFF4F46E5), size: 24),
            const SizedBox(width: 10),
            const Text('Realizar Pago', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.payment.concepto,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
                Text(widget.payment.tipo.label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ])),
              Text('\$${_fmt.format(widget.payment.monto)}',
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
            ]),
          ),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Método de pago',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A)))),
          const SizedBox(height: 10),
          Row(children: [
            _metodoOption('tarjeta_credito', 'Tarjeta Crédito', Icons.credit_card),
            const SizedBox(width: 8),
            _metodoOption('tarjeta_debito', 'Tarjeta Débito', Icons.credit_card_outlined),
            const SizedBox(width: 8),
            _metodoOption('transferencia', 'Transferencia', Icons.swap_horiz),
          ]),
          const SizedBox(height: 16),
          if (_metodoPago == 'tarjeta_credito' || _metodoPago == 'tarjeta_debito')
            _buildCardForm()
          else
            _buildTransferenciaForm(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onPaid(_metodoPago),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 8),
                Text('Pagar \$${_fmt.format(widget.payment.monto)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Pago seguro simulado — no se realizan cargos reales',
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildCardForm() => Column(children: [
    _cardField('Número de tarjeta', _cardNumberCtrl, Icons.credit_card),
    const SizedBox(height: 12),
    _cardField('Nombre del titular', _cardNameCtrl, Icons.person_outline),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _cardField('Vencimiento', _cardExpCtrl, Icons.calendar_today_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _cardField('CVV', _cardCvvCtrl, Icons.lock_outline)),
    ]),
  ]);

  Widget _buildTransferenciaForm() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Datos para transferencia',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
      const SizedBox(height: 12),
      _infoRow('Banco', 'Banco Walud Digital'),
      _infoRow('Tipo de cuenta', 'Cuenta Corriente'),
      _infoRow('Número', '0012-3456-7890'),
      _infoRow('Titular', 'Walud S.A.S'),
      _infoRow('NIT', '900.123.456-7'),
    ]),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 120, child: Text(label,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
      Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A1A7A))),
    ]),
  );

  Widget _cardField(String label, TextEditingController ctrl, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
      filled: true, fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
  );

  Widget _metodoOption(String value, String label, IconData icon) {
    final sel = _metodoPago == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _metodoPago = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            width: sel ? 1.5 : 1)),
        child: Column(children: [
          Icon(icon, color: sel ? const Color(0xFF4F46E5) : Colors.grey, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10,
            color: sel ? const Color(0xFF4F46E5) : Colors.grey[600],
            fontWeight: sel ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.center),
        ]),
      ),
    ));
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose(); _cardNameCtrl.dispose();
    _cardExpCtrl.dispose(); _cardCvvCtrl.dispose();
    super.dispose();
  }
}

class _PaymentSuccessDialog extends StatelessWidget {
  final Payment payment;
  final String  metodoPago;
  final _fmt = NumberFormat('#,##0.00', 'es');
  _PaymentSuccessDialog({required this.payment, required this.metodoPago});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380, padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 48)),
          const SizedBox(height: 20),
          const Text('¡Pago Exitoso!', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 8),
          Text('\$${_fmt.format(payment.monto)}', style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _successRow('Concepto', payment.concepto),
              _successRow('Método', _metodoPagoLabel(metodoPago)),
              _successRow('Referencia',
                'WL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
              _successRow('Fecha', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ]),
      ),
    );
  }

  Widget _successRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A7A))),
    ]),
  );

  String _metodoPagoLabel(String m) {
    switch (m) {
      case 'tarjeta_credito': return 'Tarjeta de Crédito';
      case 'tarjeta_debito':  return 'Tarjeta de Débito';
      case 'transferencia':   return 'Transferencia';
      default:                return m;
    }
  }
}

class _FacturaDialog extends StatelessWidget {
  final Payment payment;
  final _fmt = NumberFormat('#,##0.00', 'es');
  _FacturaDialog({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400, padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('WALUD', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
              Text('Salud Digital', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('FACTURA', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              Text('No. WL-${payment.id?.toString().padLeft(6, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Fecha de emisión:', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(
              payment.fechaPago != null
                  ? DateFormat('dd MMM yyyy').format(payment.fechaPago!)
                  : DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('DESCRIPCIÓN', style: TextStyle(
                  fontSize: 10, color: Colors.grey[400],
                  fontWeight: FontWeight.bold, letterSpacing: 1))),
                Text('MONTO', style: TextStyle(
                  fontSize: 10, color: Colors.grey[400],
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
              ]),
              const Divider(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(payment.concepto,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(payment.tipo.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ])),
                Text('\$${_fmt.format(payment.monto)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A7A))),
                Text('\$${_fmt.format(payment.monto)}', style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF4F46E5))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          if (payment.metodoPago != null)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Método de pago:', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(_metodoPagoLabel(payment.metodoPago!.name),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('PAGADO', style: TextStyle(
              color: Color(0xFF10B981), fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cerrar', style: TextStyle(color: Color(0xFF4F46E5)))),
          ),
        ]),
      ),
    );
  }

  String _metodoPagoLabel(String m) {
    switch (m) {
      case 'tarjeta_credito': return 'Tarjeta de Crédito';
      case 'tarjeta_debito':  return 'Tarjeta de Débito';
      case 'transferencia':   return 'Transferencia';
      default:                return m;
    }
  }
}