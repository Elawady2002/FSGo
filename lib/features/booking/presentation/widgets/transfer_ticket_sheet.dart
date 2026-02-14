import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../providers/booking_provider.dart';
import 'package:my_app/l10n/app_localizations.dart';

class TransferTicketSheet extends ConsumerStatefulWidget {
  final BookingEntity booking;

  const TransferTicketSheet({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<TransferTicketSheet> createState() => _TransferTicketSheetState();
}

class _TransferTicketSheetState extends ConsumerState<TransferTicketSheet> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (_phoneController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    final repository = ref.read(bookingRepositoryProvider);
    final result = await repository.transferBooking(
      bookingId: widget.booking.id,
      targetPhoneNumber: _phoneController.text,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (booking) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.successfullyBooked('Transfer'))),
        );
      },
    );
  }

  Future<void> _handleInvite() async {
    setState(() => _isLoading = true);
    
    final repository = ref.read(bookingRepositoryProvider);
    final result = await repository.generateInviteLink(
      bookingId: widget.booking.id,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (link) {
        Share.share(
          '${AppLocalizations.of(context)!.inviteFriendDesc}\n$link',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.transferTicket,
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Transfer to Registered User
          Text(
            l10n.transferToFriend,
            style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration(
              hintText: l10n.phoneNumber,
              prefixIcon: const Icon(CupertinoIcons.phone, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleTransfer,
              style: AppTheme.primaryButtonStyle,
              child: _isLoading 
                ? const CupertinoActivityIndicator(color: Colors.black)
                : Text(l10n.transferNow),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),
          
          // Invite New User
          Row(
            children: [
              const Icon(CupertinoIcons.link, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.inviteFriend,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.inviteFriendDesc,
            style: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleInvite,
              style: AppTheme.secondaryButtonStyle,
              child: Text(l10n.shareInviteLink),
            ),
          ),
        ],
      ),
    );
  }
}
