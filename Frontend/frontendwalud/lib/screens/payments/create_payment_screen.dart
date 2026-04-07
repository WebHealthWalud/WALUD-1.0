import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../models/user.dart';

class CreatePaymentScreen extends StatefulWidget {
  final VoidCallback? onCreated;
  const CreatePaymentScreen({super.key, this.onCreated});

  @override
  State<CreatePaymentScreen> createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends State<CreatePaymentScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl    = TextEditingController();
  final _notasCtrl    = TextEditingController();

  PaymentTipo _tipo    = PaymentTipo.consulta;
  DateTime?   _vence;
  bool        _isSaving = false;
  User?       _currentUser;

  @override
  void initState() {
    super.initState();
    AuthService.getCurrentUser().then((r) {
      if (r['success'] && mounted) setState(() => _currentUser = r['user']);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payment = Payment(
      patientId:        _currentUser!.id!,
      concepto:         _conceptoCtrl.text.trim(),
      tipo:             _tipo,
      monto:            double.parse(_montoCtrl.text.replaceAll(',', '.')),
      estadoPago:       PaymentStatus.pendiente,
      fechaVencimiento: _vence,
      notas:            _notasCtrl.text.trim().isNotEmpty ? _notasCtrl.text.trim() : null,
    );

    final r = await PaymentService.create(payment);
    setState(() => _isSaving = false);

    if (mounted) {
      if (r['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pago registrado correctamente'), backgroundColor: Color(0xFF10B981)),
        );
        widget.onCreated?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Registrar Pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Concepto *'),
              TextFormField(
                controller: _conceptoCtrl,
                decoration: _inputDecoration('Ej: Consulta Cardiología - Dr. Méndez'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _label('Tipo de servicio'),
              DropdownButtonFormField<PaymentTipo>(
                value: _tipo,
                decoration: _inputDecoration(''),
                items: PaymentTipo.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              _label('Monto *'),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('0.00').copyWith(prefixText: '\$ '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
            ])),

            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Fecha de vencimiento (opcional)'),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _vence = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF4F46E5), size: 18),
                    const SizedBox(width: 10),
                    Text(_vence != null ? DateFormat('d MMM yyyy').format(_vence!) : 'Sin vencimiento',
                      style: TextStyle(color: _vence != null ? const Color(0xFF1A1A7A) : Colors.grey)),
                    const Spacer(),
                    if (_vence != null)
                      GestureDetector(
                        onTap: () => setState(() => _vence = null),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _label('Notas (opcional)'),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: _inputDecoration('Información adicional sobre el pago...'),
              ),
            ])),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13)),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/payments/pay_now_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class PayNowScreen extends StatefulWidget {
  final List<Payment> payments;
  final VoidCallback? onPaid;

  const PayNowScreen({super.key, required this.payments, this.onPaid});

  @override
  State<PayNowScreen> createState() => _PayNowScreenState();
}

class _PayNowScreenState extends State<PayNowScreen> {
  int?         _selectedIdx;
  PaymentMethod _method    = PaymentMethod.tarjeta_credito;
  bool          _isPaying  = false;
  final _refCtrl = TextEditingController();
  final _fmt     = NumberFormat('#,##0', 'es');

  Future<void> _pay() async {
    if (_selectedIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un pago'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isPaying = true);

    final p = widget.payments[_selectedIdx!];
    final r = await PaymentService.pay(p.id!, _method.name, referencia: _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null);

    setState(() => _isPaying = false);

    if (mounted) {
      if (r['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pago procesado exitosamente'), backgroundColor: Color(0xFF10B981)),
        );
        widget.onPaid?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Realizar Pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Seleccionar pago
          const Text('Selecciona el pago a realizar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 12),
          ...List.generate(widget.payments.length, (i) {
            final p   = widget.payments[i];
            final sel = _selectedIdx == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF4F46E5).withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: sel ? 2 : 1),
                ),
                child: Row(children: [
                  Radio<int>(value: i, groupValue: _selectedIdx, onChanged: (v) => setState(() => _selectedIdx = v), activeColor: const Color(0xFF4F46E5)),
                  Expanded(child: Text(p.concepto, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('\$${_fmt.format(p.monto)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                ]),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Método de pago
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A7A))),
              const SizedBox(height: 12),
              ...PaymentMethod.values.map((m) {
                final icons = {
                  PaymentMethod.tarjeta_credito:  Icons.credit_card,
                  PaymentMethod.tarjeta_debito:   Icons.credit_card_outlined,
                  PaymentMethod.transferencia:    Icons.swap_horiz,
                  PaymentMethod.efectivo:         Icons.money,
                  PaymentMethod.otro:             Icons.payment,
                };
                final labels = {
                  PaymentMethod.tarjeta_credito:  'Tarjeta de Crédito',
                  PaymentMethod.tarjeta_debito:   'Tarjeta de Débito',
                  PaymentMethod.transferencia:    'Transferencia Bancaria',
                  PaymentMethod.efectivo:         'Efectivo',
                  PaymentMethod.otro:             'Otro',
                };
                return RadioListTile<PaymentMethod>(
                  value: m,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  activeColor: const Color(0xFF4F46E5),
                  contentPadding: EdgeInsets.zero,
                  title: Row(children: [
                    Icon(icons[m], size: 18, color: const Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Text(labels[m]!, style: const TextStyle(fontSize: 14)),
                  ]),
                );
              }),
              const SizedBox(height: 8),
              const Text('Referencia (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              TextField(
                controller: _refCtrl,
                decoration: InputDecoration(
                  hintText: 'Número de transacción, recibo...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ]),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isPaying
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selectedIdx != null
                            ? 'Pagar \$${_fmt.format(widget.payments[_selectedIdx!].monto)}'
                            : 'Selecciona un pago',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() { _refCtrl.dispose(); super.dispose(); }
}