import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

class TestFormixController extends FormixController {
  bool isDisposed = false;

  @override
  void dispose() {
    if (preventDisposal) return;
    isDisposed = true;
    super.dispose();
  }
}

class DisposalObserver extends ProviderObserver {
  final List<String> disposedProviders = [];

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    if (provider.name != null) {
      disposedProviders.add(provider.name!);
    }
  }
}

void main() {
  const navigatorKey = Key('nestedNavigator');

  testWidgets('FormixController is disposed when navigating away (keepAlive: false)', (tester) async {
    final controller = TestFormixController();
    final observer = DisposalObserver();

    await tester.pumpWidget(
      ProviderScope(
        observers: [observer],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => Formix(
                    controller: controller, // Inject our test controller
                    keepAlive: false, // Default behavior
                    child: const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initial check: not disposed
    expect(controller.isDisposed, isFalse);
    expect(observer.disposedProviders, isNot(contains('formControllerProvider')));

    // Push a new route to simulate navigation
    final navigator = tester.state<NavigatorState>(find.byKey(navigatorKey));
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const Text('Page B')));

    // Pump to trigger cleanup
    await tester.pumpAndSettle();

    // Check if disposed
    expect(controller.isDisposed, isTrue);
    expect(observer.disposedProviders, contains('formControllerProvider'));
  });

  testWidgets('FormixController is NOT disposed when navigating away if keepAlive: true (External Controller)', (tester) async {
    final controller = TestFormixController();
    final observer = DisposalObserver();

    await tester.pumpWidget(
      ProviderScope(
        observers: [observer],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => Formix(
                    controller: controller,
                    keepAlive: true,
                    child: const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(controller.isDisposed, isFalse);
    expect(observer.disposedProviders, isNot(contains('formControllerProvider')));

    // Navigate away
    final navigator = tester.state<NavigatorState>(find.byKey(navigatorKey));
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const Text('Page B')));

    await tester.pumpAndSettle();

    // Check if NOT disposed
    expect(controller.isDisposed, isFalse);
    // Note: The provider override IS disposed because the scope is disposed.
    // However, the controller itself is preserved due to preventDisposal.
    expect(observer.disposedProviders, contains('formControllerProvider'));
  });

  testWidgets('Internal FormixController is disposed when navigating away (keepAlive: false)', (tester) async {
    final observer = DisposalObserver();
    final GlobalKey<FormixState> formKey = GlobalKey<FormixState>();

    await tester.pumpWidget(
      ProviderScope(
        observers: [observer],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => Formix(
                    key: formKey,
                    keepAlive: false,
                    child: const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Ensure it's created
    final controller = formKey.currentState?.controller;
    // We access dependencies to ensure provider is built
    formKey.currentState?.provider;
    expect(controller, isNotNull);

    // Navigate away
    final navigator = tester.state<NavigatorState>(find.byKey(navigatorKey));
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const Text('Page B')));

    await tester.pumpAndSettle();

    // Check if the provider was disposed
    expect(observer.disposedProviders, contains('formControllerProvider'));
  });

  testWidgets('Internal FormixController is NOT disposed when navigating away if keepAlive: true', (tester) async {
    final observer = DisposalObserver();
    final GlobalKey<FormixState> formKey = GlobalKey<FormixState>();

    await tester.pumpWidget(
      ProviderScope(
        observers: [observer],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => Formix(
                    key: formKey,
                    keepAlive: true,
                    child: const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Ensure it's created
    final controller = formKey.currentState?.controller;
    // We access dependencies to ensure provider is built
    formKey.currentState?.provider;
    expect(controller, isNotNull);

    // Navigate away
    final navigator = tester.state<NavigatorState>(find.byKey(navigatorKey));
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const Text('Page B')));

    await tester.pumpAndSettle();

    // Check if the provider was disposed
    expect(observer.disposedProviders, isNot(contains('formControllerProvider')));
  });
}
