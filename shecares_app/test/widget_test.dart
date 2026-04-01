import 'package:flutter_test/flutter_test.dart';
import 'package:shecares_app/models/cart_item.dart';
import 'package:shecares_app/models/order.dart';
import 'package:shecares_app/providers/cart_provider.dart';
import 'package:shecares_app/services/firestore_service.dart';
import 'package:shecares_app/utils/constants.dart';
import 'package:shecares_app/utils/dummy_data.dart';

void main() {
  test('seed catalog contains 21 products', () {
    expect(SeedData.products.length, 21);
  });

  test(
    'cart pricing applies free delivery threshold and emergency surcharge',
    () async {
      final cart = CartProvider();

      await cart.addItem(
        SeedData.products.firstWhere((product) => product.finalPrice == 499),
      );
      expect(cart.deliveryFee, 0);
      expect(cart.total, 499);

      await cart.clearCart();
      await cart.addItem(
        SeedData.products.firstWhere((product) => product.finalPrice == 179),
      );
      await cart.setEmergency(true);

      expect(cart.deliveryFee, 29);
      expect(cart.emergencyFee, 49);
      expect(cart.total, 257);
    },
  );

  test('cart provider enforces the per-product quantity limit', () async {
    final cart = CartProvider();
    final product = SeedData.products.first;

    for (var i = 0; i < AppConstants.maxQuantityPerSku; i++) {
      await cart.addItem(product);
    }

    await expectLater(cart.addItem(product), throwsException);
  });

  test('local order placement decrements stock and clears the saved cart', () async {
    final service = FirestoreService.instance;
    await service.seedPhaseOneData();

    final product = (await service.getProducts(includeUnavailable: true)).first;
    const userId = 'local-test-user';
    final items = [CartItem(product: product, quantity: 1)];

    await service.saveCart(
      userId,
      items,
      isDiscreet: true,
      isEmergency: false,
    );

    final result = await service.placeOrder(
      Order(
        docId: '',
        orderId: '',
        userId: userId,
        items: items,
        address: const DeliveryAddress(
          fullName: 'Test User',
          phone: '9999999998',
          houseNo: '10A',
          street: 'Test Street',
          area: 'Satellite',
          city: 'Ahmedabad',
          pincode: '380015',
        ),
        status: OrderStatus.awaitingConfirmation,
        paymentStatus: PaymentStatus.submitted,
        paymentProvider: PaymentProvider.manualUpi,
        paymentUtr: 'TESTUTR12345',
        paymentSubmittedAt: DateTime.now(),
        subtotal: product.finalPrice,
        deliveryFee: 0,
        emergencyFee: 0,
        totalAmount: product.finalPrice,
        isDiscreet: true,
        doNotRingBell: false,
        isEmergency: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await service.verifyPayment(
      result.docId,
      adminUid: 'test-admin',
    );

    final updatedProduct = (await service.getProducts(includeUnavailable: true))
        .firstWhere((item) => item.id == product.id);
    final savedCart = await service.getCart(userId);

    expect(result.docId, isNotEmpty);
    expect(result.orderId, isNotEmpty);
    expect(updatedProduct.stockCount, product.stockCount - 1);
    expect(savedCart?.items ?? const <CartItem>[], isEmpty);
  });

  test('order placement rejects pincodes outside the Ahmedabad service area', () async {
    final service = FirestoreService.instance;
    await service.seedPhaseOneData();
    final product = (await service.getProducts(includeUnavailable: true)).first;

    await expectLater(
      service.placeOrder(
        Order(
          docId: '',
          orderId: '',
          userId: 'invalid-pincode-user',
          items: [CartItem(product: product, quantity: 1)],
          address: const DeliveryAddress(
            fullName: 'Test User',
            phone: '9999999997',
            houseNo: '11',
            street: 'Test Street',
            area: 'Remote',
            city: 'Surat',
            pincode: '395001',
          ),
          status: OrderStatus.awaitingConfirmation,
          paymentStatus: PaymentStatus.verified,
          paymentProvider: PaymentProvider.manualUpi,
          paymentUtr: 'TESTUTR12345',
          paymentSubmittedAt: DateTime.now(),
          subtotal: product.finalPrice,
          deliveryFee: 0,
          emergencyFee: 0,
          totalAmount: product.finalPrice,
          isDiscreet: true,
          doNotRingBell: false,
          isEmergency: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      throwsA(isA<OrderPlacementException>()),
    );
  });
}
