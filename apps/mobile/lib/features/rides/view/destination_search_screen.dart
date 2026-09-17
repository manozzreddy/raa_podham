import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/geocoding_repository.dart';
import '../../../theme/theme.dart';
import '../view_model/destination_search_view_model.dart';

/// A dedicated search screen for picking a ride's destination — pushed
/// from [CreateRideScreen] expecting a [DestinationSuggestion] back via
/// `Navigator.pop`, the same pattern Google Maps itself uses for place
/// search (a full search experience, not an inline dropdown crammed
/// into a form).
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(destinationSearchViewModelProvider);
    final notifier = ref.read(destinationSearchViewModelProvider.notifier);

    Future<void> selectSuggestion(DestinationPrediction prediction) async {
      final suggestion = await notifier.selectPrediction(prediction);
      if (!context.mounted) return;
      if (suggestion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't load that place. Try again."),
          ),
        );
        return;
      }
      Navigator.of(context).pop(suggestion);
    }

    final searchField = isCupertino
        ? CupertinoSearchTextField(
            controller: _controller,
            focusNode: _focusNode,
            placeholder: 'Search a destination',
            onChanged: notifier.setQuery,
          )
        : TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Search a destination',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: notifier.setQuery,
          );

    final content = Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: searchField),
        if (state.isSearching || state.isResolving)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: state.suggestions.isEmpty
              ? _EmptyState(hasQuery: state.query.trim().isNotEmpty)
              : ListView.separated(
                  itemCount: state.suggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.hairline),
                  itemBuilder: (context, index) {
                    final suggestion = state.suggestions[index];
                    return _SuggestionRow(
                      suggestion: suggestion,
                      // Resolving is a second network round trip after
                      // the tap — block further taps so it can't fire
                      // twice or race a second prediction's resolution.
                      onTap: state.isResolving
                          ? null
                          : () => selectSuggestion(suggestion),
                    );
                  },
                ),
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Destination'),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Destination')),
      body: content,
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final DestinationPrediction suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      suggestion.displayName,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final subtitle = suggestion.secondaryText.isEmpty
        ? null
        : Text(suggestion.secondaryText);
    final leading = Icon(
      isCupertino ? CupertinoIcons.location_solid : Icons.place_outlined,
    );
    final distanceMeters = suggestion.distanceMeters;
    final trailing = distanceMeters == null
        ? null
        : Text(
            _formatDistance(distanceMeters),
            style: isCupertino
                ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
                : Theme.of(context).textTheme.bodySmall,
          );

    if (isCupertino) {
      return CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _formatDistance(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          hasQuery ? 'No matches found.' : 'Search for a place to meet up.',
          textAlign: TextAlign.center,
          style: style?.copyWith(color: style.color?.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
