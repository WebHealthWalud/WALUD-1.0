import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import 'create_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _all = [];
  List<Payment> _pending = [];
  List<Payment> _completed = [];
  bool _isLoading = true;
  String _historialFilter = 'Todos';
  Map<String, dynamic> _summary = {};

  final _fmt = NumberFormat('#,##0', 'es');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      PaymentService.getAll(),
      PaymentService.getSummary(),
    ]);

    final paymentsResult = results[0];
    final summaryResult = results[1];

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (paymentsResult['success'] == true) {
          _all = List<Payment>.from(paymentsResult['payments']);
          _pending = _all
              .where((p) => p.estadoPago == PaymentStatus.pendiente)
              .toList();
          _completed = _all
              .where((p) => p.estadoPago == PaymentStatus.completado)
              .toList();
        }
        if (summaryResult['success'] == true) {
          _summary = Map<String, dynamic>.from(summaryResult['data'] ?? {});
        }
      });
    }
  }

  List<Payment> get _filteredHistorial {
    switch (_historialFilter) {
      case 'Consultas':
        return _completed.where((p) => p.tipo == PaymentTipo.consulta).toList();
      case 'Estudios':
        return _completed.where((p) => p.tipo == PaymentTipo.estudio).toList();
      default:
        return _completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF4F46E5),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildPendingSection()),
                  SliverToBoxAdapter(child: _buildHistorialSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePaymentScreen(onCreated: _load),
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add),
        label: const Text(
          'Registrar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagos y Facturación',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A7A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Administra tus servicios médicos, métodos de pago y descarga tus comprobantes fiscales en un solo lugar.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            // ✅ PayNowScreen está definida abajo en este mismo archivo
            onPressed: _pending.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PayNowScreen(payments: _pending, onPaid: _load),
                      ),
                    ),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text(
              'Pagar Ahora',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    if (_pending.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF4F46E5), size: 18),
                SizedBox(width: 8),
                Text(
                  'Pagos Pendientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A7A),
                  ),
                ),
              ],
            ),
          ),
          ..._pending.map((p) => _buildPendingRow(p)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPendingRow(Payment p) {
    final vence = p.fechaVencimiento;
    final isOverdue = vence != null && vence.isBefore(DateTime.now());
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _tipoIcon(p.tipo),
              color: const Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.concepto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A7A),
                  ),
                ),
                if (vence != null)
                  Text(
                    '${isOverdue ? "Venció" : "Vence"}: ${DateFormat('d MMM').format(vence)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_fmt.format(p.monto)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 15,
                ),
              ),
              if (vence != null)
                Text(
                  DateFormat('d MMM').format(vence),
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : Colors.grey[500],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF4F46E5), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Historial de Transacciones',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A7A),
                    ),
                  ),
                ),
                ...['Todos', 'Consultas', 'Estudios'].map((f) {
                  final active = _historialFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _historialFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF4F46E5).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                          color: active
                              ? const Color(0xFF4F46E5)
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(flex: 4, child: _tableHeader('CONCEPTO')),
                Expanded(flex: 2, child: _tableHeader('FECHA')),
                Expanded(flex: 2, child: _tableHeader('ESTADO')),
                Expanded(flex: 2, child: _tableHeader('MONTO')),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'ACCIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          if (_filteredHistorial.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No hay transacciones',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._filteredHistorial.map((p) => _buildHistorialRow(p)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _tableHeader(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildHistorialRow(Payment p) {
    final statusColor = Color(int.parse('0x${p.estadoPago.color}'));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _tipoIcon(p.tipo),
                        color: const Color(0xFF06B6D4),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.concepto,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  p.fechaPago != null
                      ? DateFormat('d MMM, yyyy').format(p.fechaPago!)
                      : '-',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.estadoPago.label.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$${_fmt.format(p.monto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A7A),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: TextButton(
                  onPressed: () => _showPaymentDetail(p),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt, size: 14),
                      SizedBox(width: 2),
                      Text('Factura', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: Colors.grey.shade100,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  void _showPaymentDetail(Payment p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'Detalle de Factura',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A7A),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _detailRow('Concepto', p.concepto),
              _detailRow('Tipo', p.tipo.label),
              _detailRow('Monto', '\$${_fmt.format(p.monto)}'),
              _detailRow('Estado', p.estadoPago.label),
              if (p.fechaPago != null)
                _detailRow(
                  'Fecha de pago',
                  DateFormat('d MMM yyyy').format(p.fechaPago!),
                ),
              if (p.metodoPago != null)
                _detailRow(
                  'Método',
                  p.metodoPago!.name.replaceAll('_', ' '),
                ),
              if (p.referenciaPago != null)
                _detailRow('Referencia', p.referenciaPago!),
              if (p.notas != null && p.notas!.isNotEmpty)
                _detailRow('Notas', p.notas!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A7A),
                ),
              ),
            ),
          ],
        ),
      );

  IconData _tipoIcon(PaymentTipo tipo) {
    switch (tipo) {
      case PaymentTipo.consulta:
        return Icons.medical_services_outlined;
      case PaymentTipo.estudio:
        return Icons.biotech_outlined;
      case PaymentTipo.seguro:
        return Icons.shield_outlined;
      case PaymentTipo.vacuna:
        return Icons.vaccines_outlined;
      case PaymentTipo.psicoterapia:
        return Icons.psychology_outlined;
      case PaymentTipo.otro:
        return Icons.payment_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PayNowScreen — incluida aquí para evitar importaciones externas
// ─────────────────────────────────────────────────────────────────────────────
class PayNowScreen extends StatefulWidget {
  final List<Payment> payments;
  final VoidCallback? onPaid;

  const PayNowScreen({super.key, required this.payments, this.onPaid});

  @override
  State<PayNowScreen> createState() => _PayNowScreenState();
}

class _PayNowScreenState extends State<PayNowScreen> {
  int? _selectedIdx;
  PaymentMethod _method = PaymentMethod.tarjeta_credito;
  bool _isPaying = false;
  final _refCtrl = TextEditingController();
  final _fmt = NumberFormat('#,##0', 'es');

  Future<void> _pay() async {
    if (_selectedIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un pago'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isPaying = true);

    final p = widget.payments[_selectedIdx!];
    final r = await PaymentService.pay(
      p.id!,
      _method.name,
      referencia:
          _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
    );

    setState(() => _isPaying = false);

    if (mounted) {
      if (r['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago procesado exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onPaid?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Realizar Pago',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el pago a realizar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A7A),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.payments.length, (i) {
              final p = widget.payments[i];
              final sel = _selectedIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF4F46E5).withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade200,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _selectedIdx,
                        onChanged: (v) => setState(() => _selectedIdx = v),
                        activeColor: const Color(0xFF4F46E5),
                      ),
                      Expanded(
                        child: Text(
                          p.concepto,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '\$${_fmt.format(p.monto)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Método de pago',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...PaymentMethod.values.map((m) {
                    const icons = {
                      PaymentMethod.tarjeta_credito: Icons.credit_card,
                      PaymentMethod.tarjeta_debito:
                          Icons.credit_card_outlined,
                      PaymentMethod.transferencia: Icons.swap_horiz,
                      PaymentMethod.efectivo: Icons.money,
                      PaymentMethod.otro: Icons.payment,
                    };
                    const labels = {
                      PaymentMethod.tarjeta_credito: 'Tarjeta de Crédito',
                      PaymentMethod.tarjeta_debito: 'Tarjeta de Débito',
                      PaymentMethod.transferencia: 'Transferencia Bancaria',
                      PaymentMethod.efectivo: 'Efectivo',
                      PaymentMethod.otro: 'Otro',
                    };
                    return RadioListTile<PaymentMethod>(
                      value: m,
                      groupValue: _method,
                      onChanged: (v) => setState(() => _method = v!),
                      activeColor: const Color(0xFF4F46E5),
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(
                            icons[m],
                            size: 18,
                            color: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            labels[m]!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text(
                    'Referencia (opcional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _refCtrl,
                    decoration: InputDecoration(
                      hintText: 'Número de transacción, recibo...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _selectedIdx != null
                                ? 'Pagar \$${_fmt.format(widget.payments[_selectedIdx!].monto)}'
                                : 'Selecciona un pago',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }
}