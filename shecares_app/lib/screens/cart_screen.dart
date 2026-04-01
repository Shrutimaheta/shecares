import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/checkout_settings.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/app_main_menu.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController(text: AppConstants.defaultCity);
  final _pincodeController = TextEditingController();
  final _noteController = TextEditingController();
  final _utrController = TextEditingController();

  int _step = 0;
  bool _doNotRingBell = false;
  bool _saveAsDefault = false;
  bool _isPlacingOrder = false;
  String _selectedSlot = 'Tomorrow, 10 AM - 1 PM';
  PaymentProvider _selectedPaymentProvider = PaymentProvider.cod;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    final address = user?.defaultAddress;
    _nameController.text = user?.fullName ?? '';
    _phoneController.text = user?.phone ?? '';
    if (address != null) {
      _houseController.text = address.houseNo;
      _streetController.text = address.street;
      _areaController.text = address.area;
      _cityController.text = address.city;
      _pincodeController.text = address.pincode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _noteController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  List<String> _deliverySlots(CartProvider cart) {
    return [
      if (cart.isEmergency && cart.canUseEmergency)
        'Express today, within 2-4 hours',
      'Today, 7 PM - 10 PM',
      'Tomorrow, 7 AM - 10 AM',
      'Tomorrow, 10 AM - 1 PM',
      'Tomorrow, 4 PM - 8 PM',
    ];
  }

  void _syncSlot(CartProvider cart) {
    final slots = _deliverySlots(cart);
    if (!slots.contains(_selectedSlot)) {
      _selectedSlot = slots.first;
    }
  }

  bool _validateAddressInputs({bool showMessage = false}) {
    final fullName = _nameController.text.trim();
    if (fullName.length < 2) {
      if (showMessage) {
        _showMessage('Please enter your full name.');
      }
      return false;
    }

    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      if (showMessage) {
        _showMessage('Enter a valid 10-digit Indian mobile number.');
      }
      return false;
    }

    if (_houseController.text.trim().isEmpty) {
      if (showMessage) {
        _showMessage('Please enter your house or flat number.');
      }
      return false;
    }
    if (_streetController.text.trim().isEmpty) {
      if (showMessage) {
        _showMessage('Please enter your street or society.');
      }
      return false;
    }
    if (_areaController.text.trim().isEmpty) {
      if (showMessage) {
        _showMessage('Please enter your area or landmark.');
      }
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      if (showMessage) {
        _showMessage('Please enter the city.');
      }
      return false;
    }

    final pincode = int.tryParse(_pincodeController.text.trim());
    if (pincode == null) {
      if (showMessage) {
        _showMessage('Pincode must be 6 digits.');
      }
      return false;
    }
    if (pincode < AppConstants.minServicePincode ||
        pincode > AppConstants.maxServicePincode) {
      if (showMessage) {
        _showMessage('Sorry, we currently deliver only within Ahmedabad.');
      }
      return false;
    }

    return true;
  }

  bool _validatePaymentFields(CheckoutSettings settings) {
    if (_selectedPaymentProvider == PaymentProvider.cod) {
      return true;
    }

    final utr = _utrController.text.trim().toUpperCase();
    if (utr.isEmpty) {
      _showMessage('Enter the UTR or transaction reference from your UPI app.');
      return false;
    }
    if (utr.length < settings.minimumUtrLength) {
      _showMessage(
        'UTR should be at least ${settings.minimumUtrLength} characters long.',
      );
      return false;
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(utr)) {
      _showMessage('UTR can contain only letters and numbers.');
      return false;
    }
    return true;
  }

  Future<void> _placeOrder(CheckoutSettings settings) async {
    final auth = context.read<AuthService>();
    final cart = context.read<CartProvider>();
    final user = auth.currentUser;

    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }
    if (!_validateAddressInputs(showMessage: true)) {
      setState(() => _step = 1);
      return;
    }
    if (!_validatePaymentFields(settings)) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final service = FirestoreService.instance;
      final address = DeliveryAddress(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        houseNo: _houseController.text.trim(),
        street: _streetController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );

      final result = await service.placeOrder(
        Order(
          docId: '',
          orderId: service.generateOrderId(),
          userId: user.uid,
          items: cart.items,
          address: address,
          status: OrderStatus.awaitingConfirmation,
          paymentStatus: _selectedPaymentProvider == PaymentProvider.cod
              ? PaymentStatus.verified
              : PaymentStatus.submitted,
          paymentProvider: _selectedPaymentProvider,
          subtotal: cart.subtotal,
          deliveryFee: cart.deliveryFee,
          emergencyFee: cart.emergencyFee,
          totalAmount: cart.total,
          isDiscreet: cart.isDiscreet,
          doNotRingBell: _doNotRingBell,
          isEmergency: cart.isEmergency,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          etaLabel: service.etaLabelForStatus(OrderStatus.awaitingConfirmation),
          deliverySlot: _selectedSlot,
          customerNote: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          paymentUtr: _selectedPaymentProvider == PaymentProvider.cod
              ? null
              : _utrController.text.trim(),
          paymentSubmittedAt: _selectedPaymentProvider == PaymentProvider.cod
              ? null
              : DateTime.now(),
        ),
      );

      if (_saveAsDefault || user.defaultAddress == null) {
        await auth.saveCustomerProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          defaultAddress: address,
        );
      }

      await cart.clearCart(persist: false);
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderSuccess,
        arguments: {'orderDocId': result.docId, 'orderId': result.orderId},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    _syncSlot(cart);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart and checkout')),
      drawer: const AppMainMenu(currentRoute: AppRoutes.cart),
      body: SafeArea(
        child: Column(
          children: [
            _StepHeader(step: _step),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _step == 0
                    ? _buildReviewStep(context, cart)
                    : _step == 1
                    ? _buildAddressStep(context, cart)
                    : _buildPaymentStep(context, cart),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: StreamBuilder<CheckoutSettings>(
          stream: FirestoreService.instance.checkoutSettingsStream(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? CheckoutSettings.defaults();
            return Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: cart.items.isEmpty || _isPlacingOrder
                        ? null
                        : () {
                            if (_step == 0) {
                              setState(() => _step = 1);
                            } else if (_step == 1) {
                              if (_validateAddressInputs()) {
                                setState(() => _step = 2);
                              }
                            } else {
                              _placeOrder(settings);
                            }
                          },
                    child: Text(
                      _isPlacingOrder
                          ? 'Submitting order...'
                          : (_step == 2
                                ? 'Confirm and place order'
                                : 'Continue'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewStep(BuildContext context, CartProvider cart) {
    if (cart.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EmptyStateCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is empty',
            message:
                'Add sanitary pads, baby diapers, or adult diapers to continue.',
            actionLabel: 'Shop now',
            onAction: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
        ),
      );
    }

    final amountForFreeDelivery =
        (AppConstants.freeDeliveryThreshold - cart.subtotal).clamp(0, 99999);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Card(
          color: const Color(0xFFFFF7F4),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review before payment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirm your essentials, privacy preferences, and delivery slot before you pay through UPI.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(label: '${cart.itemCount} items'),
                    _MiniPill(label: _selectedSlot),
                    _MiniPill(
                      label: cart.isDiscreet
                          ? 'Discreet packaging on'
                          : 'Standard packaging',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (cart.deliveryFee > 0)
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('Unlock free delivery'),
              subtitle: Text(
                'Add Rs ${amountForFreeDelivery.toStringAsFixed(0)} more to cross Rs ${AppConstants.freeDeliveryThreshold.toStringAsFixed(0)}.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...cart.items.map(
          (item) => CartItemWidget(
            item: item,
            onUpdateQuantity: (product, quantity) =>
                cart.updateQuantity(product, quantity),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Discreet packaging'),
                  subtitle: const Text('Hide product names on the parcel.'),
                  value: cart.isDiscreet,
                  onChanged: (value) => cart.setDiscreet(value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Emergency delivery'),
                  subtitle: Text(
                    cart.canUseEmergency
                        ? '2 to 4 hours for sanitary-product-only orders with Rs 49 surcharge.'
                        : 'Emergency delivery is available only for sanitary-pad-only carts.',
                  ),
                  value: cart.isEmergency,
                  onChanged: cart.canUseEmergency
                      ? (value) async {
                          await cart.setEmergency(value);
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            final slots = _deliverySlots(cart);
                            _selectedSlot = slots.first;
                          });
                        }
                      : null,
                ),
                const Divider(),
                _SummaryRow(label: 'Subtotal', value: cart.subtotal),
                _SummaryRow(
                  label: 'Delivery',
                  valueLabel: cart.deliveryFee == 0
                      ? 'FREE'
                      : 'Rs ${cart.deliveryFee.toStringAsFixed(0)}',
                ),
                if (cart.isEmergency)
                  _SummaryRow(
                    label: 'Emergency surcharge',
                    value: cart.emergencyFee,
                  ),
                const Divider(),
                _SummaryRow(label: 'Total', value: cart.total, bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddressStep(BuildContext context, CartProvider cart) {
    final slots = _deliverySlots(cart);

    return Form(
      key: _addressFormKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Please enter your full name.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      counterText: '',
                    ),
                    validator: (value) =>
                        !RegExp(
                          r'^[6-9][0-9]{9}$',
                        ).hasMatch((value ?? '').trim())
                        ? 'Enter a valid 10-digit Indian mobile number.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _houseController,
                    decoration: const InputDecoration(
                      labelText: 'Flat or house number',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your house or flat number.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street or society',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your street or society.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area or landmark',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your area or landmark.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter the city.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      counterText: '',
                    ),
                    validator: (value) {
                      final pincode = int.tryParse((value ?? '').trim());
                      if (pincode == null) {
                        return 'Pincode must be 6 digits.';
                      }
                      if (pincode < AppConstants.minServicePincode ||
                          pincode > AppConstants.maxServicePincode) {
                        return 'Sorry, we currently deliver only within Ahmedabad.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery slot and notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots
                        .map(
                          (slot) => ChoiceChip(
                            label: Text(slot),
                            selected: _selectedSlot == slot,
                            onSelected: (_) =>
                                setState(() => _selectedSlot = slot),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Delivery note (optional)',
                      hintText:
                          'Example: Leave at security, call on arrival, or use side gate.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Do not ring the bell'),
                    subtitle: const Text(
                      'Useful for privacy-sensitive or sleeping-household deliveries.',
                    ),
                    value: _doNotRingBell,
                    onChanged: (value) =>
                        setState(() => _doNotRingBell = value),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save as my default address'),
                    value: _saveAsDefault,
                    onChanged: (value) =>
                        setState(() => _saveAsDefault = value ?? false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(BuildContext context, CartProvider cart) {
    return StreamBuilder<CheckoutSettings>(
      stream: FirestoreService.instance.checkoutSettingsStream(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? CheckoutSettings.defaults();
        if (!settings.manualUpiEnabled &&
            _selectedPaymentProvider == PaymentProvider.manualUpi) {
          _selectedPaymentProvider = PaymentProvider.cod;
        }
        final preferences = StringBuffer(
          cart.isDiscreet ? 'Discreet packaging' : 'Standard packaging',
        );
        if (_doNotRingBell) {
          preferences.write(', do not ring bell');
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFFFF7F4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<PaymentProvider>(
                      title: const Text('Cash on Delivery (COD)'),
                      subtitle: const Text('Pay when the order arrives.'),
                      value: PaymentProvider.cod,
                      groupValue: _selectedPaymentProvider,
                      onChanged: (value) =>
                          setState(() => _selectedPaymentProvider = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<PaymentProvider>(
                      title: const Text('Pay with UPI'),
                      subtitle: const Text(
                        'Pay now with Google Pay, PhonePe, Paytm, etc.',
                      ),
                      value: PaymentProvider.manualUpi,
                      groupValue: _selectedPaymentProvider,
                      onChanged: settings.manualUpiEnabled
                          ? (value) => setState(
                              () => _selectedPaymentProvider = value!,
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!settings.manualUpiEnabled)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'UPI is temporarily unavailable. You can still place this order with Cash on Delivery.',
                        ),
                      ),
                    if (_selectedPaymentProvider ==
                        PaymentProvider.manualUpi) ...[
                      const Divider(height: 32),
                      Text(
                        'Pay with UPI and submit your UTR',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.paymentInstructions,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F5D65),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PaymentInfoRow(
                        label: 'Payee',
                        value: settings.payeeName,
                      ),
                      _PaymentInfoRow(label: 'UPI ID', value: settings.upiId),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: settings.upiId),
                            );
                            if (!mounted) {
                              return;
                            }
                            _showMessage('UPI ID copied.');
                          },
                          icon: const Icon(Icons.copy_all_outlined),
                          label: const Text('Copy UPI ID'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Pay exactly Rs ${cart.total.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _QrPreview(path: settings.qrImagePath),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _utrController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'UTR / transaction reference number',
                          hintText:
                              '${settings.minimumUtrLength}-character UTR from your UPI app',
                          helperText:
                              'Enter only letters and numbers. This is required before order placement.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final order review',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReviewLine(
                      label: 'Deliver to',
                      value:
                          '${_nameController.text.trim()}, ${_houseController.text.trim()}, ${_areaController.text.trim()}',
                    ),
                    _ReviewLine(label: 'Slot', value: _selectedSlot),
                    _ReviewLine(
                      label: 'Payment',
                      value: _selectedPaymentProvider == PaymentProvider.cod
                          ? 'Cash on Delivery'
                          : 'Manual UPI review',
                    ),
                    _ReviewLine(
                      label: 'Preferences',
                      value: preferences.toString(),
                    ),
                    if (_noteController.text.trim().isNotEmpty)
                      _ReviewLine(
                        label: 'Delivery note',
                        value: _noteController.text.trim(),
                      ),
                    const Divider(height: 28),
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} x ${item.quantity}',
                              ),
                            ),
                            Text('Rs ${item.totalPrice.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    _SummaryRow(label: 'Subtotal', value: cart.subtotal),
                    _SummaryRow(
                      label: 'Delivery',
                      valueLabel: cart.deliveryFee == 0
                          ? 'FREE'
                          : 'Rs ${cart.deliveryFee.toStringAsFixed(0)}',
                    ),
                    if (cart.isEmergency)
                      _SummaryRow(
                        label: 'Emergency surcharge',
                        value: cart.emergencyFee,
                      ),
                    const Divider(),
                    _SummaryRow(label: 'Total', value: cart.total, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if ((path ?? '').trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7D8DE)),
        ),
        child: const Text(
          'No QR image uploaded yet. You can still pay using the UPI ID shown above.',
        ),
      );
    }

    return FutureBuilder<String?>(
      future: StorageService.instance.resolveDownloadUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final url = snapshot.data;
        if ((url ?? '').isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7D8DE)),
            ),
            child: const Text(
              'QR image is unavailable right now. Use the UPI ID instead.',
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(url!, height: 220, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  static const _labels = ['Review', 'Address', 'Payment'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final active = index <= step;
          final current = index == step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index == _labels.length - 1 ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.22)
                      : const Color(0xFFE6D7DB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF8E7C84),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7DB)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7A676F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value,
    this.valueLabel,
    this.bold = false,
  });

  final String label;
  final double? value;
  final String? valueLabel;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            valueLabel ?? 'Rs ${value?.toStringAsFixed(0) ?? '0'}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
