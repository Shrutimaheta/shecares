import 'package:flutter/material.dart';

import '../utils/constants.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderDocId,
    required this.orderId,
  });

  final String orderDocId;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, size: 88, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Order submitted',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('Order ID: $orderId'),
              const SizedBox(height: 16),
              const Text(
                'Your manual UPI payment reference is now waiting for admin review.',
              ),
              const SizedBox(height: 10),
              const Text('What happens next:'),
              const SizedBox(height: 8),
              const Text('1. The SheCares team verifies your payment UTR.'),
              const Text('2. Once verified, the order is confirmed and packed.'),
              const Text('3. You can track every status update in the app.'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.tracking,
                    arguments: orderDocId,
                  ),
                  child: const Text('Track order'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (_) => false,
                  ),
                  child: const Text('Back to home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
