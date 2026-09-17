import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/geocoding_repository.dart';
import '../../../theme/theme.dart';
import '../models/ride.dart';
import '../view_model/create_ride_view_model.dart';
import '../view_model/rides_view_model.dart';
import 'destination_search_screen.dart';
import 'share_invite_screen.dart';

/// The new-ride form: a name, a required destination (picked via the
/// dedicated [DestinationSearchScreen], not typed inline), an optional
/// scheduled start time, notes, and a cover photo, with a Create button
/// pinned to the bottom — not inline with the scrolling fields, so it's
/// always reachable without scrolling down first. Hands off to
/// [ShareInviteScreen] — not back to this screen — once the ride exists.
///
/// Doubles as the edit-ride form when [ride] is non-null: same fields,
/// pre-filled from it (see [CreateRideViewModel.build]), submitting saves
/// the edit and pops back to `RideDetailScreen` instead of pushing
/// [ShareInviteScreen].
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key, this.ride});

  final Ride? ride;

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _scheduledController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only [_nameController]/[_notesController] need this — free-typing
    // fields the user edits directly, so (unlike destination/scheduled
    // below) they're only ever set here, once, not resynced on every
    // build afterwards. The initial state already has these prefilled
    // when editing (see [CreateRideViewModel.build]).
    final initial = ref.read(createRideViewModelProvider(widget.ride));
    _nameController.text = initial.name;
    _notesController.text = initial.notes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _scheduledController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = createRideViewModelProvider(widget.ride);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final isEditing = widget.ride != null;

    ref.listen<CreateRideUiState>(provider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    // Set on every build, not just via a ref.listen (which never fires
    // for the very first frame) — both fields need to show their actual
    // content (including an edited ride's pre-filled destination, or
    // "Right away" for no scheduled time) from the very first frame, not
    // just a greyed hint that could read as "nothing chosen yet".
    final destinationText = state.selectedDestination?.displayName ?? '';
    if (_destinationController.text != destinationText) {
      _destinationController.text = destinationText;
    }
    final scheduledText = state.scheduledAt == null
        ? 'Right away'
        : formatScheduledTime(state.scheduledAt!);
    if (_scheduledController.text != scheduledText) {
      _scheduledController.text = scheduledText;
    }

    Future<void> pickDestination() async {
      final result = await context.push<DestinationSuggestion>(
        '/rides/destination-search',
      );
      if (result != null) notifier.selectDestination(result);
    }

    Future<void> submit() async {
      final existingRide = widget.ride;
      final ride = existingRide == null
          ? await notifier.createRide()
          : await notifier.updateRide(existingRide.id);
      if (!context.mounted || ride == null) return;
      ref.invalidate(ridesViewModelProvider);
      if (existingRide == null) {
        context.push('/rides/share-invite', extra: ride);
      } else {
        // Always a plain pop, even when clearing the scheduled time just
        // flipped this ride active ("start right away") — RideDetailScreen
        // (still underneath, never disposed) has its own guard for that
        // case. A go('/home') here would replace the whole stack instead
        // of just popping back onto it, tearing down and recreating
        // HomeScreen — which cancels HomeViewModel's in-flight GPS/RTDB
        // position reporting before it ever completes, leaving every
        // rider (including self) stuck showing 0 riders until the next
        // cold start. Same reasoning as RideDetailScreen's own pop below.
        context.pop();
      }
    }

    final canSubmit =
        state.name.trim().isNotEmpty &&
        state.selectedDestination != null &&
        !state.isCreating &&
        !state.isUploadingPhoto;

    final nameField = isCupertino
        ? CupertinoTextField(
            controller: _nameController,
            placeholder: 'Sunday Sunrise Ride',
            onChanged: notifier.setName,
          )
        : TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ride name',
              hintText: 'Sunday Sunrise Ride',
            ),
            onChanged: notifier.setName,
          );

    final destinationField = isCupertino
        ? CupertinoTextField(
            controller: _destinationController,
            placeholder: 'Search a destination',
            readOnly: true,
            showCursor: false,
            suffix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(CupertinoIcons.search, size: 18),
            ),
          )
        : TextField(
            controller: _destinationController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'Search a destination',
              suffixIcon: Icon(Icons.search),
            ),
          );

    final scheduledField = isCupertino
        ? CupertinoTextField(
            controller: _scheduledController,
            placeholder: 'Right away',
            readOnly: true,
            showCursor: false,
            suffix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(CupertinoIcons.clock, size: 18),
            ),
          )
        : TextField(
            controller: _scheduledController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Starts',
              hintText: 'Right away',
              suffixIcon: Icon(Icons.schedule),
            ),
          );

    final notesField = isCupertino
        ? CupertinoTextField(
            controller: _notesController,
            placeholder: 'What to bring, meeting details, ...',
            minLines: 2,
            maxLines: 4,
            onChanged: notifier.setNotes,
          )
        : TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'What to bring, meeting details, ...',
              alignLabelWithHint: true,
            ),
            onChanged: notifier.setNotes,
          );

    final submitLabel = isEditing ? 'Save changes' : 'Create ride';
    final submitButton = isCupertino
        ? CupertinoButton.filled(
            onPressed: canSubmit ? submit : null,
            child: state.isCreating
                ? const CupertinoActivityIndicator()
                : Text(submitLabel),
          )
        : FilledButton(
            onPressed: canSubmit ? submit : null,
            child: state.isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          );

    final formContent = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        nameField,
        const SizedBox(height: 16),
        // AbsorbPointer keeps the field itself inert (no cursor, no
        // keyboard) while the GestureDetector around it turns the whole
        // thing into a button that opens the dedicated search screen.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pickDestination,
          child: AbsorbPointer(child: destinationField),
        ),
        const _DestinationHint(),
        const SizedBox(height: 20),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              _pickScheduledStart(context, notifier, state.scheduledAt),
          child: AbsorbPointer(child: scheduledField),
        ),
        if (state.scheduledAt != null)
          _ClearScheduledHint(onClear: () => notifier.setScheduledAt(null)),
        const SizedBox(height: 20),
        notesField,
        const SizedBox(height: 20),
        _CoverPhotoPicker(
          coverPhotoUrl: state.coverPhotoUrl,
          isUploading: state.isUploadingPhoto,
          onPick: notifier.pickAndUploadCoverPhoto,
          onRemove: notifier.removeCoverPhoto,
        ),
      ],
    );

    final footer = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: submitButton,
      ),
    );

    final title = isEditing ? 'Edit ride' : 'New ride';

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: formContent),
              footer,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: formContent,
      bottomNavigationBar: footer,
    );
  }

  /// Opens a date+time picker for [CreateRideUiState.scheduledAt] — no
  /// existing picker precedent anywhere in this app to follow instead, so
  /// this just applies the file's own existing `isCupertino` branching to
  /// the platform picker each side already ships: `CupertinoDatePicker`
  /// in a modal sheet, or `showDatePicker` + `showTimePicker` in sequence.
  Future<void> _pickScheduledStart(
    BuildContext context,
    CreateRideViewModel notifier,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final initial = current ?? now.add(const Duration(hours: 1));

    if (isCupertino) {
      var picked = initial;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => Container(
          height: 260,
          color: CupertinoTheme.of(sheetContext).scaffoldBackgroundColor,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () {
                    notifier.setScheduledAt(picked);
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  minimumDate: now,
                  initialDateTime: initial,
                  onDateTimeChanged: (value) => picked = value,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    notifier.setScheduledAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _DestinationHint extends StatelessWidget {
  const _DestinationHint();

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Shown as a pin for everyone on the map',
        style: style?.copyWith(color: style.color?.withValues(alpha: 0.7)),
      ),
    );
  }
}

/// Sits under the "Starts" field once a time is picked — same caption
/// position [_DestinationHint] uses, but tappable: it needs to sit
/// outside that field's `AbsorbPointer` (which swallows every tap inside
/// it, including a suffix icon's) to actually be tappable on its own,
/// separately from the field's "open the picker" tap.
class _ClearScheduledHint extends StatelessWidget {
  const _ClearScheduledHint({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodySmall;

    // The tappable Padding is inside the button (not the other way
    // around) — otherwise the hit area is just the Row's own tight,
    // text-height bounds, which is too thin a target to reliably tap.
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCupertino ? CupertinoIcons.clear_circled_solid : Icons.cancel,
            size: 14,
            color: style?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Start right away instead',
            style: style?.copyWith(color: style.color?.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );

    // Same platform tap-feedback split as _AddPhotoTarget/_RemovePhotoButton
    // below — Material ink or Cupertino's opacity dim, rather than the
    // silent GestureDetector this used to be.
    final button = isCupertino
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onClear,
            child: content,
          )
        : Material(
            color: Colors.transparent,
            child: InkWell(onTap: onClear, child: content),
          );

    // Being a direct ListView child, this would otherwise be handed the
    // full row width as a tight constraint — both CupertinoButton and
    // InkWell fill whatever box they're given, so without Align here the
    // clickable/ink area stretches across the whole row instead of
    // hugging just the icon+text (plus content's own padding). Align
    // loosens that constraint, so the button shrink-wraps to its content
    // and only that shrunk box sits flush left.
    return Align(alignment: Alignment.centerLeft, child: button);
  }
}

class _CoverPhotoPicker extends StatelessWidget {
  const _CoverPhotoPicker({
    required this.coverPhotoUrl,
    required this.isUploading,
    required this.onPick,
    required this.onRemove,
  });

  final String? coverPhotoUrl;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelLarge;
    final photoUrl = coverPhotoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COVER PHOTO (OPTIONAL)',
          style: labelStyle?.copyWith(
            color: labelStyle.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: isUploading
                ? Container(
                    color: AppColors.sunriseAmber.withValues(alpha: 0.08),
                    child: Center(
                      child: isCupertino
                          ? const CupertinoActivityIndicator()
                          : const CircularProgressIndicator(),
                    ),
                  )
                : photoUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _RemovePhotoButton(onPressed: onRemove),
                      ),
                    ],
                  )
                : _AddPhotoTarget(onPressed: onPick),
          ),
        ),
      ],
    );
  }
}

/// The empty cover-photo placeholder — a big tappable box, so unlike the
/// "Starts"/Destination fields (styled as text inputs, no ripple, same as
/// a real `TextField` on tap-to-focus) this reads as a button and gets
/// proper platform tap feedback: Material ink, or Cupertino's opacity
/// dim.
class _AddPhotoTarget extends StatelessWidget {
  const _AddPhotoTarget({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelLarge;

    final content = Container(
      color: AppColors.sunriseAmber.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCupertino
                ? CupertinoIcons.photo
                : Icons.add_photo_alternate_outlined,
            color: AppColors.sunriseAmber,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'Add a cover photo',
            style: labelStyle?.copyWith(color: AppColors.sunriseAmber),
          ),
        ],
      ),
    );

    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: content,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onPressed, child: content),
    );
  }
}

/// The small "×" over a picked cover photo — same platform-feedback
/// reasoning as [_AddPhotoTarget], just circular to match its shape.
class _RemovePhotoButton extends StatelessWidget {
  const _RemovePhotoButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _icon = Icon(Icons.close, size: 16, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.all(4),
        minimumSize: Size.zero,
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        onPressed: onPressed,
        child: _icon,
      );
    }
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(padding: EdgeInsets.all(4), child: _icon),
      ),
    );
  }
}
