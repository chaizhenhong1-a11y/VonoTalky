import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../data/services/contact_service.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final controller = TextEditingController();
  final service = ContactService();
  List<ChatUser> results = const [];
  bool searching = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (controller.text.trim().length < 2) {
      setState(
        () => error = 'Enter a full email or at least 2 name characters.',
      );
      return;
    }
    setState(() {
      searching = true;
      error = null;
    });
    try {
      final users = await service.search(controller.text);
      if (mounted) setState(() => results = users);
    } catch (_) {
      if (mounted) setState(() => error = 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add contact')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Email or username',
              prefixIcon: const Icon(Icons.person_search_rounded),
              suffixIcon: IconButton(
                onPressed: searching ? null : _search,
                icon: const Icon(Icons.search_rounded),
              ),
              filled: true,
              fillColor: const Color(0xFFF6F3F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (searching) const LinearProgressIndicator(color: Color(0xFFB49ADF)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child: results.isEmpty && !searching && error == null
              ? const _SearchHint()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(indent: 66),
                  itemBuilder: (_, index) => _SearchResultTile(
                    user: results[index],
                    service: service,
                    onNotice: _notice,
                  ),
                ),
        ),
      ],
    ),
  );

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.user,
    required this.service,
    required this.onNotice,
  });
  final ChatUser user;
  final ContactService service;
  final ValueChanged<String> onNotice;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE5DAF5),
      backgroundImage: user.photoUrl == null
          ? null
          : NetworkImage(user.photoUrl!),
      child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
    ),
    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(user.email),
    trailing: StreamBuilder<String?>(
      stream: service.requestStatus(user.uid),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == 'pending') return const Chip(label: Text('Pending'));
        if (status == 'accepted') return const Chip(label: Text('Contact'));
        if (status == 'rejected') return const Chip(label: Text('Declined'));
        return FilledButton.tonalIcon(
          onPressed: () async {
            try {
              await service.sendRequest(user.uid);
              onNotice('Friend request sent');
            } catch (error) {
              onNotice(error.toString().replaceFirst('Bad state: ', ''));
            }
          },
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
          label: const Text('Add'),
        );
      },
    ),
  );
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_search_outlined, size: 56, color: Color(0xFFB49ADF)),
        SizedBox(height: 12),
        Text('Find someone by email or username'),
      ],
    ),
  );
}
