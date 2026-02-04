import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Added for lastOrNull
import '../controllers/riverpod_controller.dart';

/// Service for interacting with DevTools extension.
class FormixDevToolsService {
  static final Map<String, RiverpodFormController> _activeControllers = {};
  static final Set<String> _allFormHistory = <String>{};
  static String? _latestActiveId; // Added

  static bool _extensionsRegistered = false;

  /// Register a controller for DevTools monitoring.
  static void registerController(String id, RiverpodFormController controller) {
    _activeControllers[id] = controller;

    // Refresh history order: move to end
    _allFormHistory.remove(id);
    _allFormHistory.add(id);

    _latestActiveId = id; // Added
    _maybeRegisterExtensions();
  }

  /// Unregister a controller.
  static void unregisterController(String id) {
    _activeControllers.remove(id);
    // We keep it in _allFormHistory but it's no longer in _activeControllers
    if (_latestActiveId == id) {
      // Added
      _latestActiveId = _activeControllers.keys.lastOrNull; // Added
    } // Added
  }

  static void _maybeRegisterExtensions() {
    if (_extensionsRegistered) return;

    // Use a local variable to avoid issues with static access during async
    if (!kDebugMode) return;
    _extensionsRegistered = true;

    // Log the DevTools URL for easy access (Native only)
    if (!kIsWeb) {
      dev.Service.getInfo()
          .then((info) {
            final serverUri = info.serverUri;
            if (serverUri != null) {
              final String base = serverUri.toString();

              // Construct the WebSocket URI (ws://.../token/ws)
              final String wsScheme = serverUri.scheme == 'https' ? 'wss' : 'ws';
              final String wsBase = base.replaceFirst(
                serverUri.scheme,
                wsScheme,
              );
              final String wsUri = wsBase.endsWith('/') ? '${wsBase}ws' : '$wsBase/ws';

              // Construct the DevTools Base (http://.../token/devtools/)
              final String devToolsBase = base.endsWith('/') ? '${base}devtools/' : '$base/devtools/';

              // Build the final deep link to the formix_ext route
              final String fullUrl = "${devToolsBase}formix_ext?uri=$wsUri";

              debugPrint('\x1B[32m[Formix]\x1B[0m 🛠️  Inspector: $fullUrl');
            }
          })
          .catchError((e) {
            debugPrint('[Formix] Failed to get DevTools info: $e');
          });
    }

    // List all form IDs (active and history)
    dev.registerExtension('ext.formix.listForms', (method, parameters) async {
      try {
        return dev.ServiceExtensionResponse.result(
          jsonEncode({
            'latestActiveId': _latestActiveId,
            'forms': _allFormHistory
                .toList()
                .reversed
                .map(
                  (id) => {
                    'id': id,
                    'isActive': _activeControllers.containsKey(id),
                  },
                )
                .toList(),
          }),
        );
      } catch (e) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    // Get detail for a specific form
    dev.registerExtension('ext.formix.getFormDetails', (
      method,
      parameters,
    ) async {
      try {
        final formId = parameters['formId'];
        final controller = _activeControllers[formId];

        if (controller == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Form not found: $formId',
          );
        }

        final state = controller.state;
        return dev.ServiceExtensionResponse.result(
          jsonEncode(
            {
              'values': state.values,
              'validations': {
                for (final entry in state.validations.entries)
                  entry.key: {
                    'isValid': entry.value.isValid,
                    'errorMessage': entry.value.errorMessage,
                    'isValidating': entry.value.isValidating,
                  },
              },
              'dirtyStates': state.dirtyStates,
              'touchedStates': state.touchedStates,
              'isSubmitting': state.isSubmitting,
              'fieldCount': state.values.length,
              'validationDurations': {
                for (final entry in controller.validationDurations.entries) entry.key: entry.value.inMicroseconds,
              },
            },
            toEncodable: (nonEncodable) {
              if (nonEncodable is DateTime) {
                return nonEncodable.toIso8601String();
              }
              return nonEncodable.toString();
            },
          ),
        );
      } catch (e) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });
  }
}
