import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/finance/presentation/screens/add_transaction_screen.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';

class _RadialOption {
  final IconData icon;
  const _RadialOption(this.icon);
}

/// Tombol tambah global — dipasang di navbar, di antara menu Catatan & Keuangan.
///
/// - Di luar Dashboard: tap langsung membuka layar tambah sesuai tab aktif.
/// - Di Dashboard: tekan & tahan memunculkan menu radial (fan) berisi 3
///   pilihan. Geser jari ke salah satu ikon lalu lepas untuk langsung
///   membuka layar tambah terkait.
class RadialAddButton extends StatefulWidget {
  final int currentIndex; // 0=Dashboard, 1=Notes, 2=Finance, 3=Tasks

  const RadialAddButton({super.key, required this.currentIndex});

  @override
  State<RadialAddButton> createState() => _RadialAddButtonState();
}

class _RadialAddButtonState extends State<RadialAddButton> {
  static const double _buttonSize = 60;
  static const double _innerRadius = 42;
  static const double _outerRadius = 108;

  static const _options = [
    _RadialOption(Icons.sticky_note_2_outlined), // 0: Catatan
    _RadialOption(Icons.account_balance_wallet_outlined), // 1: Keuangan
    _RadialOption(Icons.task_alt_outlined), // 2: Tugas
  ];

  final GlobalKey _buttonKey = GlobalKey();
  final ValueNotifier<int?> _hoveredWedge = ValueNotifier(null);
  OverlayEntry? _overlayEntry;
  Offset? _buttonCenter;

  bool get _isDashboard => widget.currentIndex == 0;

  @override
  void dispose() {
    _removeOverlay();
    _hoveredWedge.dispose();
    super.dispose();
  }

  void _openScreenFor(int optionIndex) {
    late final Widget screen;
    switch (optionIndex) {
      case 0:
        screen = const NoteEditorScreen();
        break;
      case 1:
        screen = const AddTransactionScreen();
        break;
      default:
        screen = const AddTaskScreen();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _handleDirectTap() {
    switch (widget.currentIndex) {
      case 1:
        _openScreenFor(0);
        break;
      case 2:
        _openScreenFor(1);
        break;
      case 3:
        _openScreenFor(2);
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _buttonCenter = box.localToGlobal(box.size.center(Offset.zero));
    _hoveredWedge.value = null;
    _showOverlay();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_buttonCenter == null) return;
    _hoveredWedge.value = _resolveWedge(details.globalPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    final selected = _hoveredWedge.value;
    _removeOverlay();
    if (selected != null) _openScreenFor(selected);
  }

  void _onPanCancel() => _removeOverlay();

  int? _resolveWedge(Offset globalPosition) {
    final center = _buttonCenter!;
    final dx = globalPosition.dx - center.dx;
    final dy = center.dy - globalPosition.dy; // dy > 0 berarti di atas tombol
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < _innerRadius - 12) return null; // masih di area tombol
    if (dy < 0) return null; // di bawah tombol, di luar area fan

    final angle = math.atan2(dy, dx) * 180 / math.pi; // 0=kanan,90=atas,180=kiri
    if (angle >= 120) return 0; // Catatan (kiri)
    if (angle >= 60) return 1; // Keuangan (tengah)
    return 2; // Tugas (kanan)
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _FanMenuOverlay(
        center: _buttonCenter!,
        innerRadius: _innerRadius,
        outerRadius: _outerRadius,
        options: _options,
        hoveredWedge: _hoveredWedge,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isDashboard ? null : _handleDirectTap,
      onPanStart: _isDashboard ? _onPanStart : null,
      onPanUpdate: _isDashboard ? _onPanUpdate : null,
      onPanEnd: _isDashboard ? _onPanEnd : null,
      onPanCancel: _isDashboard ? _onPanCancel : null,
      child: Container(
        key: _buttonKey,
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}

class _FanMenuOverlay extends StatelessWidget {
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final List<_RadialOption> options;
  final ValueNotifier<int?> hoveredWedge;

  const _FanMenuOverlay({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.options,
    required this.hoveredWedge,
  });

  static const List<double> _midAnglesDeg = [150, 90, 30];

  @override
  Widget build(BuildContext context) {
    final size = outerRadius * 2;
    return Positioned(
      left: center.dx - outerRadius,
      top: center.dy - outerRadius,
      width: size,
      height: size,
      child: IgnorePointer(
        child: ValueListenableBuilder<int?>(
          valueListenable: hoveredWedge,
          builder: (_, hovered, __) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _FanPainter(
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    hoveredWedge: hovered,
                  ),
                ),
                ...List.generate(options.length, (i) {
                  final rad = _midAnglesDeg[i] * math.pi / 180;
                  final iconRadius = (innerRadius + outerRadius) / 2;
                  final dx = outerRadius + math.cos(rad) * iconRadius;
                  final dy = outerRadius - math.sin(rad) * iconRadius;
                  final isHovered = hovered == i;
                  return Positioned(
                    left: dx - 18,
                    top: dy - 18,
                    child: AnimatedScale(
                      scale: isHovered ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          options[i].icon,
                          size: 22,
                          color: isHovered
                              ? Colors.black
                              : Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FanPainter extends CustomPainter {
  final double innerRadius;
  final double outerRadius;
  final int? hoveredWedge;

  _FanPainter({
    required this.innerRadius,
    required this.outerRadius,
    required this.hoveredWedge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const wedgeSweep = math.pi / 3; // 60 derajat
    final startAngles = [
      math.pi, // 180° kiri
      math.pi + wedgeSweep, // 240°
      math.pi + 2 * wedgeSweep, // 300°
    ];

    for (var i = 0; i < 3; i++) {
      final isHovered = hoveredWedge == i;
      final fillPaint = Paint()
        ..color = isHovered
            ? Colors.white.withOpacity(0.95)
            : const Color(0xFF2A2A2E).withOpacity(0.95)
        ..style = PaintingStyle.fill;

      final start = startAngles[i];
      final path = Path()
        ..moveTo(
          center.dx + innerRadius * math.cos(start),
          center.dy + innerRadius * math.sin(start),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          start,
          wedgeSweep,
          false,
        )
        ..lineTo(
          center.dx + outerRadius * math.cos(start + wedgeSweep),
          center.dy + outerRadius * math.sin(start + wedgeSweep),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          start + wedgeSweep,
          -wedgeSweep,
          false,
        )
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FanPainter oldDelegate) =>
      oldDelegate.hoveredWedge != hoveredWedge;
}