import 'package:flutter/material.dart';

import '../../data/models/friend_request.dart';
import '../../data/services/contact_service.dart';

class FriendRequestsPage extends StatelessWidget {
  FriendRequestsPage({super.key});
  final ContactService service = ContactService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Friend requests')),
        body: StreamBuilder<List<FriendRequest>>(
          stream: service.incomingRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Unable to load requests'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final requests = snapshot.data!;
            if (requests.isEmpty) {
              return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mark_email_read_outlined, size: 56, color: Color(0xFFB49ADF)),
                  SizedBox(height: 12),
                  Text('No pending friend requests'),
                ]),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(indent: 66),
              itemBuilder: (_, index) => _RequestTile(request: requests[index], service: service),
            );
          },
        ),
      );
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({required this.request, required this.service});
  final FriendRequest request;
  final ContactService service;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool working = false;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: widget.service.user(widget.request.senderId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return const SizedBox(height: 70);
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE5DAF5),
              backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
              child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(user.email),
            trailing: working
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => _respond(false), icon: const Icon(Icons.close_rounded)),
                    FilledButton(onPressed: () => _respond(true), child: const Text('Accept')),
                  ]),
          );
        },
      );

  Future<void> _respond(bool accept) async {
    setState(() => working = true);
    try {
      if (accept) {
        await widget.service.accept(widget.request);
      } else {
        await widget.service.reject(widget.request);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update request')),
        );
        setState(() => working = false);
      }
    }
  }
}
