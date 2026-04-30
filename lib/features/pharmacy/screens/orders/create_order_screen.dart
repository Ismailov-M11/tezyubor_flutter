import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../models/order_model.dart';
import '../../providers/clients_provider.dart';
import '../../providers/orders_provider.dart';

class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _totalController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (UzPhoneFormatter.isComplete(_phoneController.text)) {
      final digits = UzPhoneFormatter.digitsOnly(_phoneController.text);
      final clients = ref.read(clientsProvider).clients;
      final match = clients.where((c) =>
          UzPhoneFormatter.digitsOnly(c.phone) == digits).firstOrNull;
      if (match?.name != null && _nameController.text.isEmpty) {
        _nameController.text = match!.name!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _commentController.dispose();
    _totalController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final totalRaw = _totalController.text.trim().replaceAll(',', '.');
    final req = CreateOrderRequest(
      pharmacyComment: _commentController.text.trim(),
      medicinesTotal: totalRaw.isEmpty ? null : double.tryParse(totalRaw),
      customerName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      customerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    final success = await ref.read(ordersProvider.notifier).createOrder(req);
    setState(() => _isLoading = false);

    if (mounted) {
      final l10n = context.l10n;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createOrder)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.newOrder,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Комментарий к заказу (обязательное)
            CustomTextField(
              label: '${l10n.orderCommentLbl} *',
              hint: l10n.orderCommentHint,
              controller: _commentController,
              prefixIcon: const Icon(Icons.comment_outlined),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fillAllFields : null,
            ),
            const SizedBox(height: 12),

            // Сумма заказа (необязательное)
            CustomTextField(
              label: l10n.orderAmountLbl,
              hint: '150000',
              controller: _totalController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.payments_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed =
                    double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null || parsed < 0) return l10n.fillAllFields;
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Имя клиента (необязательное)
            CustomTextField(
              label: l10n.customer,
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 12),

            // Телефон клиента (необязательное)
            CustomTextField(
              label: l10n.phone,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              inputFormatters: [UzPhoneFormatter()],
            ),
            const SizedBox(height: 24),

            CustomButton(
              label: l10n.createOrder,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
