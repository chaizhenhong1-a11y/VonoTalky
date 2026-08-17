import 'package:flutter/material.dart';

import '../../data/models/shared_pet.dart';
import '../../data/models/pet_invite.dart';
import '../../data/services/pet_invite_service.dart';
import '../../data/services/shared_pet_service.dart';
import 'shared_pet_detail_page.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {
  final service = SharedPetService();
  final inviteService = PetInviteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      body: SafeArea(
        child: StreamBuilder<List<SharedPet>>(
          stream: service.watchMyPets(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pets = snapshot.data!;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _summary(pets)),
                SliverToBoxAdapter(child: _inviteInbox()),
                if (pets.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPetCenter(),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    sliver: SliverList.separated(
                      itemCount: pets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _PetCard(
                          pet: pet,
                          myId: service.myId,
                          service: service,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SharedPetDetailPage(petId: pet.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: _inviteHint()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _inviteInbox() {
    return StreamBuilder<List<PetInvite>>(
      stream: inviteService.watchMyPendingInvites(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? const <PetInvite>[];
        if (!snapshot.hasData || invites.isEmpty) {
          return const SizedBox.shrink();
        }

        final incoming = invites
            .where((invite) => invite.receiverId == inviteService.myId)
            .toList();
        final outgoing = invites
            .where((invite) => invite.senderId == inviteService.myId)
            .toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFFFDDE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFFFEDF4),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFFFF6F9D),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pet invitations',
                          style: TextStyle(
                            color: Color(0xFF443847),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Shared-pet invitations from your chats',
                          style: TextStyle(
                            color: Color(0xFF978A99),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF668F),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '${invites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (incoming.isNotEmpty) ...[
                const SizedBox(height: 13),
                ...incoming.map(_incomingInviteCard),
              ],
              if (outgoing.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...outgoing.map(_outgoingInviteCard),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _incomingInviteCard(PetInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFF7F1FC)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.pets_rounded, color: Color(0xFF9B6CC5), size: 18),
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
                  style: const TextStyle(
                    color: Color(0xFF514453),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Raise “${invite.petName}” together',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF928496),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decline',
            onPressed: () => _rejectInvite(invite),
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: Color(0xFF9E8590),
            ),
          ),
          FilledButton(
            onPressed: () => _acceptInvite(invite),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9B6CC5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _outgoingInviteCard(PetInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 17,
            color: Color(0xFF9B79C8),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Waiting for ${invite.receiverName} · ${invite.petName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF786A7C),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEAF2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, color: Color(0xFFFF6F9D)),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Center',
                  style: TextStyle(
                    color: Color(0xFF2E2632),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pets you are raising with friends',
                  style: TextStyle(
                    color: Color(0xFF968A9A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const _FirebaseBadge(),
        ],
      ),
    );
  }

  Widget _summary(List<SharedPet> pets) {
    final totalStreak = pets.fold<int>(0, (sum, pet) => sum + pet.streakDays);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEAF2), Color(0xFFF1EAFE)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryStat(
              Icons.pets_rounded,
              '${pets.length}',
              'Shared pets',
            ),
          ),
          Container(width: 1, height: 42, color: const Color(0x22A58BA7)),
          Expanded(
            child: _summaryStat(
              Icons.local_fire_department_rounded,
              '$totalStreak',
              'Total streak days',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8C6AB8), size: 21),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF403347),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF918493),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _inviteHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFDCE7)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFFFF0F5),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFFFF759E),
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raise another pet',
                  style: TextStyle(
                    color: Color(0xFF443947),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'The next phase will connect this to the friend-chat invite flow.',
                  style: TextStyle(
                    color: Color(0xFF958A97),
                    fontSize: 10,
                    height: 1.3,
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

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.myId,
    required this.service,
    required this.onTap,
  });

  final SharedPet pet;
  final String myId;
  final SharedPetService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final friendName = pet.friendName(myId);
    final friendId = pet.friendId(myId);
    final myContribution = pet.contributionFor(myId);
    final friendContribution = pet.contributionFor(friendId);
    final total = myContribution + friendContribution;
    final myPercent = total == 0 ? 50 : (myContribution * 100 / total).round();
    final friendPercent = 100 - myPercent;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(27),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _MiniFlameAvatar(
                    stage: pet.evolutionStage,
                    theme: pet.petTheme,
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: StreamBuilder<int>(
                      stream: service.watchIncomingCareRequestCount(pet.id),
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) return const SizedBox.shrink();

                        return Container(
                          constraints: const BoxConstraints(minWidth: 21),
                          height: 21,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF668F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.petName,
                            style: const TextStyle(
                              color: Color(0xFF382F3B),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          'Lv.${pet.level}',
                          style: const TextStyle(
                            color: Color(0xFFFF7DA4),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'with $friendName',
                      style: const TextStyle(
                        color: Color(0xFF948997),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _EvolutionChip(stage: pet.evolutionStage),
                    const SizedBox(height: 6),
                    StreamBuilder<int>(
                      stream: service.watchIncomingCareRequestCount(pet.id),
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) {
                          return const SizedBox(height: 3);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_active_rounded,
                                size: 13,
                                color: Color(0xFFFF668F),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                count == 1
                                    ? '1 care request'
                                    : '$count care requests',
                                style: const TextStyle(
                                  color: Color(0xFFCE5276),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: Color(0xFFFF7A6B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${pet.streakDays} days',
                          style: const TextStyle(
                            color: Color(0xFF6C5D70),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF7DA4),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Bond ${pet.bondPercent()}%',
                          style: const TextStyle(
                            color: Color(0xFF6C5D70),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _ContributionBar(
                      you: myPercent,
                      friend: friendPercent,
                      friendName: friendName,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4B9C6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionBar extends StatelessWidget {
  const _ContributionBar({
    required this.you,
    required this.friend,
    required this.friendName,
  });

  final int you;
  final int friend;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: you <= 0 ? 1 : you,
                  child: Container(color: const Color(0xFFFF7DA4)),
                ),
                Expanded(
                  flex: friend <= 0 ? 1 : friend,
                  child: Container(color: const Color(0xFFE9E2EC)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'You $you%',
              style: const TextStyle(
                color: Color(0xFFA091A3),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$friendName $friend%',
              style: const TextStyle(
                color: Color(0xFFA091A3),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniFlameAvatar extends StatelessWidget {
  const _MiniFlameAvatar({required this.stage, required this.theme});

  final PetEvolutionStage stage;
  final String theme;

  Color get _themeColor => switch (theme) {
    'violet' => const Color(0xFF9C70DB),
    'sunset' => const Color(0xFFFF8A65),
    'ocean' => const Color(0xFF5B9DE8),
    _ => const Color(0xFFFF7196),
  };

  Color get _color {
    final base = _themeColor;
    return switch (stage) {
      PetEvolutionStage.seed => Color.lerp(base, Colors.white, .18)!,
      PetEvolutionStage.spark => base,
      PetEvolutionStage.flame => Color.lerp(
        base,
        const Color(0xFF7B5AD7),
        .35,
      )!,
      PetEvolutionStage.nova => Color.lerp(base, const Color(0xFF496FE6), .55)!,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 78,
      decoration: BoxDecoration(
        color: _color.withAlpha(24),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: stage == PetEvolutionStage.nova ? 52 : 46,
            color: _color,
          ),
          if (stage == PetEvolutionStage.nova)
            const Positioned(
              top: 7,
              right: 8,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: Color(0xFFFFD967),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvolutionChip extends StatelessWidget {
  const _EvolutionChip({required this.stage});

  final PetEvolutionStage stage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          stage.label,
          style: const TextStyle(
            color: Color(0xFF8A67A7),
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FirebaseBadge extends StatelessWidget {
  const _FirebaseBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0D9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Color(0xFF9A692E),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyPetCenter extends StatelessWidget {
  const _EmptyPetCenter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 43,
              color: Color(0xFFFF78A0),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No shared pets yet',
            style: TextStyle(
              color: Color(0xFF3D3340),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your Firebase Pet Center is ready. Start a shared pet from a friend chat in the next phase.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF938795),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Pet Center could not load.\n\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
