import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/pending_auth_action.dart';
import 'providers/cart_provider.dart';
import 'screens/admin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_success_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wellness_screen.dart';
import 'services/app_bootstrap.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.instance.initialize();
  final authService = AuthService();
  await authService.initialize();
  runApp(SheCaresApp(authService: authService));
}

class SheCaresApp extends StatelessWidget {
  const SheCaresApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..attachUser(auth.currentUser),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light(),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            Route<dynamic> protectedRoute({
              required WidgetBuilder builder,
              required PendingAuthAction action,
            }) {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (!authService.isSignedIn) {
                authService.setPendingAction(action);
                return MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                  settings: settings,
                );
              }
              return MaterialPageRoute(builder: builder, settings: settings);
            }

            switch (settings.name) {
              case AppRoutes.splash:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case AppRoutes.login:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case AppRoutes.register:
                return MaterialPageRoute(builder: (_) => const RegisterScreen());
              case AppRoutes.forgotPassword:
                return MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                );
              // Block admin from customer routes
              case AppRoutes.home:
            case AppRoutes.products:
            case AppRoutes.productDetail:
            case AppRoutes.cart:
            case AppRoutes.orderSuccess:
            case AppRoutes.orders:
            case AppRoutes.tracking:
            case AppRoutes.profile:
            case AppRoutes.wellness:
              final auth = Provider.of<AuthService>(context, listen: false);
              if (auth.isSignedIn && auth.isAdmin) {
                // If admin, always redirect to admin panel
                return MaterialPageRoute(builder: (_) => const AdminScreen());
              }
              // Normal customer navigation
              switch (settings.name) {
                case AppRoutes.home:
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                case AppRoutes.products:
                  return MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      initialCategory: settings.arguments as dynamic,
                    ),
                  );
                case AppRoutes.productDetail:
                  return MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: settings.arguments as dynamic,
                    ),
                  );
                case AppRoutes.cart:
                  return protectedRoute(
                    builder: (_) => const CartScreen(),
                    action: const PendingAuthAction(
                      type: PendingAuthActionType.openCart,
                    ),
                  );
                case AppRoutes.orderSuccess:
                  final args =
                      settings.arguments as Map<String, dynamic>? ?? const {};
                  return protectedRoute(
                    builder: (_) => OrderSuccessScreen(
                      orderDocId: args['orderDocId'] as String? ?? '',
                      orderId: args['orderId'] as String? ?? '',
                    ),
                    action: const PendingAuthAction(
                      type: PendingAuthActionType.openOrders,
                    ),
                  );
                case AppRoutes.orders:
                  return protectedRoute(
                    builder: (_) => const OrdersScreen(),
                    action: const PendingAuthAction(
                      type: PendingAuthActionType.openOrders,
                    ),
                  );
                case AppRoutes.tracking:
                  return protectedRoute(
                    builder: (_) => OrderTrackingScreen(
                      orderDocId: settings.arguments as String? ?? '',
                    ),
                    action: const PendingAuthAction(
                      type: PendingAuthActionType.openOrders,
                    ),
                  );
                case AppRoutes.profile:
                  return protectedRoute(
                    builder: (_) => const ProfileScreen(),
                    action: const PendingAuthAction(
                      type: PendingAuthActionType.openProfile,
                    ),
                  );
                case AppRoutes.wellness:
                  return MaterialPageRoute(
                    builder: (_) => const WellnessScreen(),
                  );
              }
              break;
            case AppRoutes.admin:
              return MaterialPageRoute(builder: (_) => const AdminScreen());
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    ),
  );
}
}