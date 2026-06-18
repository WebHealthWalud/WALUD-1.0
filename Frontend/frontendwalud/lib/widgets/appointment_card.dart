import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(AppointmentStatus)? onStatusChange;
  final bool showActions;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onDelete,
    this.onStatusChange,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Getters correctos del modelo actualizado
    final statusColor = Color(int.parse('0x${appointment.statusColor}'));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header con estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          // ✅ statusLabel en vez de getStatusText()
                          appointment.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showActions && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirm(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Médico
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF4F46E5), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A7A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Fecha y hora
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(appointment.dateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Motivo ✅ muestra el valor real en vez del placeholder
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason.isNotEmpty
                          ? appointment.reason
                          : 'Sin información adicional',
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Acciones de estado
              if (showActions &&
                  onStatusChange != null &&
                  appointment.status == AppointmentStatus.pendiente) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text('Realizar'),
                      onPressed: () =>
                          onStatusChange!(AppointmentStatus.realizada),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancelar'),
                      onPressed: () =>
                          onStatusChange!(AppointmentStatus.cancelada),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}