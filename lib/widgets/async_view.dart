import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../theme/pp_theme.dart';

/// Renders one of loading / error / empty / data for a `Future`, in the
/// PlantPal visual language. Pair with a `key` bump to force a refetch.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.emptyWhen,
    this.emptyLabel = 'Nothing here yet',
    this.emptyIcon = LucideIcons.sprout,
    this.padding = const EdgeInsets.symmetric(vertical: 60),
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload)
      builder;
  final bool Function(T data)? emptyWhen;
  final String emptyLabel;
  final IconData emptyIcon;
  final EdgeInsets padding;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  /// The last value that loaded successfully. Kept so a *reload* (pull to
  /// refresh, or an action asking for fresh data) can keep showing the
  /// current content instead of blanking the whole screen back to a spinner.
  T? _lastData;

  Future<void> _reload() async {
    setState(() {
      _future = widget.load();
    });
    try {
      await _future;
    } catch (_) {
      // Surfaced by the FutureBuilder below; nothing to do here.
    }
  }

  /// Wraps the error / empty state so it's horizontally centred with a
  /// sensible top offset, instead of pinned to the top-left corner. Uses a
  /// full-width Row rather than `Center` so it's safe inside an unbounded
  /// scroll view too.
  Widget _center(Widget child) {
    final top = widget.padding.resolve(TextDirection.ltr).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(40, top > 0 ? top + 20 : 60, 40, 40),
      child: Row(
        children: [Expanded(child: Center(child: child))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // Only blank to a spinner on the very first load. Any later reload
          // keeps the last good content on screen (with pull-to-refresh's
          // own indicator doing the "loading" signalling).
          if (_lastData != null) {
            return widget.builder(context, _lastData as T, _reload);
          }
          return Padding(
            padding: widget.padding,
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: PP.forest),
              ),
            ),
          );
        }
        if (snap.hasError) {
          if (_lastData != null) {
            // A reload failed — keep showing what we had rather than
            // replacing the screen with an error block.
            return widget.builder(context, _lastData as T, _reload);
          }
          return _center(_ErrorBlock(error: snap.error!, onRetry: _reload));
        }
        final data = snap.data as T;
        _lastData = data;
        if (widget.emptyWhen?.call(data) ?? false) {
          return _center(
              _EmptyBlock(icon: widget.emptyIcon, label: widget.emptyLabel));
        }
        return widget.builder(context, data, _reload);
      },
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is ApiException
        ? (error as ApiException).message
        : 'Something went wrong.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: PP.amberBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(LucideIcons.triangleAlert, color: PP.amberFg),
        ),
        const SizedBox(height: 14),
        Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.6))),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: PP.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text('Try again',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: PP.bone)),
          ),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: PP.pale1,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: PP.forest),
        ),
        const SizedBox(height: 14),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.55))),
      ],
    );
  }
}

/// Snackbar helper in the app's tone.
void showPPSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? PP.danger : PP.ink,
      content: Text(message,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: PP.bone)),
    ));
}
