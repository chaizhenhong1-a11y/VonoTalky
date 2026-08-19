part of '../../../pages/real_chat_room_page.dart';

class _PetQuickAction extends StatelessWidget {
  const _PetQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: disabled
          ? const Color(0xFFF4F1F4)
          : const Color(0xFFFFF0F5),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: disabled
                    ? const Color(0xFFB9B0B8)
                    : const Color(0xFFFF7196),
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? const Color(0xFFA59CA4)
                      : const Color(0xFF5A4A5E),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetInviteBanner extends StatelessWidget {
  const _PetInviteBanner({
    required this.invite,
    required this.mine,
    required this.onAccept,
    required this.onReject,
  });

  final PetInvite invite;
  final bool mine;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEDF4), Color(0xFFF2ECFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D8EF)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.pets_rounded,
              color: Color(0xFF9B6CC5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine
                      ? 'Pet invite sent'
                      : '${invite.senderName} invited you to raise a pet',
                  style: const TextStyle(
                    color: Color(0xFF4B3B53),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pet name: ${invite.petName}',
                  style: const TextStyle(
                    color: Color(0xFF837589),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!mine) ...[
            IconButton(
              onPressed: onReject,
              tooltip: 'Decline',
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF9B7C8C),
              ),
            ),
            FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9B6CC5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Accept'),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.schedule_rounded,
                color: Color(0xFF9B7C8C),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}