import 'package:flutter/material.dart';

import '../../animation/pet_actor.dart';
import '../../data/models/pet_invite.dart';
import '../../data/models/shared_pet.dart';
import '../../data/services/pet_invite_service.dart';
import '../../data/services/shared_pet_service.dart';
import 'shared_pet_detail_page.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {
  final SharedPetService service = SharedPetService();
  final PetInviteService inviteService = PetInviteService();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<SharedPet>>(
          stream: service.watchMyPets(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            final pets = snapshot.data!;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                SliverToBoxAdapter(child: _compactInviteBanner()),
                if (pets.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPetCenter(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                    sliver: SliverList.separated(
                      itemCount: pets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _SimplePetCard(
                          pet: pet,
                          myId: service.myId,
                          onTap: () => _openPet(pet),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_rounded, color: colors.primary, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Center',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pets you are raising with friends',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInviteBanner() {
    return StreamBuilder<List<PetInvite>>(
      stream: inviteService.watchMyPendingInvites(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? const <PetInvite>[];
        if (invites.isEmpty) return const SizedBox(height: 2);

        final incoming = invites
            .where((invite) => invite.receiverId == inviteService.myId)
            .toList();
        final outgoing = invites
            .where((invite) => invite.senderId == inviteService.myId)
            .toList();

        final colors = Theme.of(context).colorScheme;
        final label = incoming.isNotEmpty
            ? '${incoming.length} pet invitation${incoming.length == 1 ? '' : 's'}'
            : '${outgoing.length} invitation${outgoing.length == 1 ? '' : 's'} waiting';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
          child: Material(
            color: colors.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: () => _showInvites(incoming, outgoing),
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      incoming.isNotEmpty
                          ? Icons.mail_outline_rounded
                          : Icons.schedule_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInvites(
    List<PetInvite> incoming,
    List<PetInvite> outgoing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet invitations',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (incoming.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...incoming.map(
                    (invite) => _IncomingInviteTile(
                      invite: invite,
                      onAccept: () async {
                        Navigator.pop(sheetContext);
                        await _acceptInvite(invite);
                      },
                      onDecline: () async {
                        Navigator.pop(sheetContext);
                        await _rejectInvite(invite);
                      },
                    ),
                  ),
                ],
                if (outgoing.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...outgoing.map(
                    (invite) => _OutgoingInviteTile(invite: invite),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptInvite(PetInvite invite) async {
    try {
      await inviteService.acceptInvite(invite);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${invite.petName} was added to your Pet Center'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _rejectInvite(PetInvite invite) async {
    try {
      await inviteService.rejectInvite(invite);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Pet invitation declined'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  void _openPet(SharedPet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharedPetDetailPage(petId: pet.id)),
    );
  }
}

class _SimplePetCard extends StatelessWidget {
  const _SimplePetCard({
    required this.pet,
    required this.myId,
    required this.onTap,
  });

  final SharedPet pet;
  final String myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final friendName = pet.friendName(myId);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.primary.withValues(alpha: .10)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 172,
                child: Center(
                  child: PetActor(
                    // This is exactly the same PetActor used by the floating pet.
                    // It replaces the old flame-person avatar on Pet Center.
                    visualSize: 150,
                    hitSize: 168,
                    onDragUpdate: (_) {},
                    onDragEnd: () {},
                    onTap: onTap,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'with $friendName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LevelChip(level: pet.level),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.favorite_rounded,
                      label: 'Bond',
                      value: '${pet.bondPercent()}%',
                      color: const Color(0xFFFF7199),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '${pet.streakDays} days',
                      color: const Color(0xFFFF826B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: const Icon(Icons.pets_rounded, size: 18),
                  label: const Text('View pet'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          color: colors.primary,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingInviteTile extends StatelessWidget {
  const _IncomingInviteTile({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final PetInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: colors.surface,
              child: Icon(Icons.pets_rounded, size: 18, color: colors.primary),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${invite.senderName} invited you',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Raise “${invite.petName}” together',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Decline',
              onPressed: onDecline,
              icon: Icon(
                Icons.close_rounded,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
            ),
            FilledButton(onPressed: onAccept, child: const Text('Accept')),
          ],
        ),
      ),
    );
  }
}

class _OutgoingInviteTile extends StatelessWidget {
  const _OutgoingInviteTile({required this.invite});

  final PetInvite invite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 17, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for ${invite.receiverName} · ${invite.petName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPetCenter extends StatelessWidget {
  const _EmptyPetCenter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 44),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 180,
            child: Center(
              child: PetActor(
                visualSize: 145,
                hitSize: 165,
                onDragUpdate: (_) {},
                onDragEnd: () {},
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No shared pets yet',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Start a shared pet from a friend chat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 38, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Pet Center could not load.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
