import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/app_window.dart';
import 'package:taif_alamin/presentation/cubits/backup_cubit/backup_cubit.dart';
import 'package:taif_alamin/presentation/cubits/backup_cubit/backup_state.dart';
import 'package:taif_alamin/utils/snack_bar_util.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  static const _primary = Color(0xFF003763);

  @override
  Widget build(BuildContext context) {
    return AppWindow(
      body: BlocConsumer<BackupCubit, BackupState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            SnackBarUtil.showSuccess(context, state.message ?? 'تمت العملية.');
          } else if (state.hasError) {
            SnackBarUtil.showError(context, state.error ?? 'حدث خطأ.');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'النسخ الاحتياطي والاستعادة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _ActionCard(
                          icon: Icons.backup_outlined,
                          title: 'إنشاء نسخة احتياطية',
                          description:
                              'نسخ ملف قاعدة البيانات إلى مكان تختاره على الجهاز.',
                          buttonLabel: 'اختيار مكان الحفظ',
                          busy: state.isBackingUp,
                          enabled: !state.isWorking,
                          onPressed: () => context.read<BackupCubit>().backup(),
                        ),
                        const SizedBox(height: 20),
                        _ActionCard(
                          icon: Icons.restore_outlined,
                          title: 'استعادة من نسخة احتياطية',
                          description:
                              'اختيار ملف نسخة احتياطية واستبدال قاعدة البيانات الحالية. '
                              'لن يتم حذف القاعدة القديمة، بل ستُحفظ باسم taif_alamin.db.pak',
                          buttonLabel: 'اختيار ملف للاستعادة',
                          danger: true,
                          busy: state.isRestoring,
                          enabled: !state.isWorking,
                          onPressed: () => _confirmRestore(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.isWorking)
                const ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تأكيد الاستعادة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'سيتم استبدال قاعدة البيانات الحالية بالملف الذي ستختاره. '
            'النسخة الحالية ستُحفظ باسم taif_alamin.db.pak ولن تُحذف.\n\n'
            'هل تريد المتابعة؟',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'متابعة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) cubit.restore();
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool busy;
  final bool enabled;
  final bool danger;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.busy,
    required this.enabled,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003763);
    final accent = danger ? Colors.red : primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x28000000)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), offset: Offset(1, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF66758C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onPressed: (enabled && !busy) ? onPressed : null,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.folder_open, size: 18),
            label: Text(
              buttonLabel,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}