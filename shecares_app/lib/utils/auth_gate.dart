import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pending_auth_action.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import 'constants.dart';

Future<void> requireCustomerAction(
  BuildContext context,
  PendingAuthAction action,
) async {
  final auth = context.read<AuthService>();
  if (!auth.isSignedIn) {
    auth.setPendingAction(action);
    await Navigator.pushNamed(context, AppRoutes.login);
    return;
  }

  await executePendingAuthAction(context, action, fromAuthFlow: false);
}

Future<void> completePendingAuthFlow(BuildContext context) async {
  final auth = context.read<AuthService>();
  final action = auth.consumePendingAction();
  if (action == null) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    return;
  }

  await executePendingAuthAction(context, action, fromAuthFlow: true);
}

Future<void> executePendingAuthAction(
  BuildContext context,
  PendingAuthAction action, {
  required bool fromAuthFlow,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    switch (action.type) {
      case PendingAuthActionType.addToCart:
        final product = action.product;
        if (product == null) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
          return;
        }
        for (var i = 0; i < action.quantity; i++) {
          await context.read<CartProvider>().addItem(product);
        }
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text('${product.name} added to your cart.')),
        );
        if (fromAuthFlow) {
          Navigator.pop(context);
        }
        return;
      case PendingAuthActionType.buyNow:
        final product = action.product;
        if (product == null) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
          return;
        }
        final cart = context.read<CartProvider>();
        if (cart.quantityOf(product) == 0) {
          for (var i = 0; i < action.quantity; i++) {
            await cart.addItem(product);
          }
        }
        if (!context.mounted) {
          return;
        }
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.cart, (_) => false);
        return;
      case PendingAuthActionType.openCart:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.cart, (_) => false);
        return;
      case PendingAuthActionType.openOrders:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orders, (_) => false);
        return;
      case PendingAuthActionType.openProfile:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profile, (_) => false);
        return;
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
    if (fromAuthFlow) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }
}
