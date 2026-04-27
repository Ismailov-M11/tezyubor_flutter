import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';

class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _totalController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final req = CreateOrderRequest(
      medicinesTotal: double.parse(_totalController.text.replaceAll(',', '.')),
      customerName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      customerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      customerAddress: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );

    final success = await ref.read(ordersProvider.notifier).createOrder(req);
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ создан')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания заказа')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
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
                Text(
                  'Новый заказ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Сумма лекарств *',
              hint: '150000',
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.medication),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите сумму';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Некорректная сумма';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Имя клиента',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Телефон клиента',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Адрес доставки',
              controller: _addressController,
              prefixIcon: const Icon(Icons.location_on_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Создать заказ',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
