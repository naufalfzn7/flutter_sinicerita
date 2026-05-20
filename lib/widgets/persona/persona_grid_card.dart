import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../models/persona_model.dart';

/// Reusable card widget untuk menampilkan persona dalam grid layout.
///
/// Menampilkan:
/// - Avatar (CachedNetworkImage dalam ClipOval 56x56, placeholder jika null)
/// - Nama (bold, centered, max 1 line, ellipsis)
/// - Deskripsi (max 2 lines, ellipsis, smaller grey text)
/// - Vote counts (thumb_up + count, thumb_down + count, tanpa button)
/// - Card dengan rounded corners dan elevation
/// - Tap seluruh card triggers [onTap] callback
class PersonaGridCard extends StatelessWidget {
  final PersonaModel persona;
  final VoidCallback onTap;

  const PersonaGridCard({
    super.key,
    required this.persona,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Avatar
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: persona.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: persona.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 28),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 28),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 28),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Name
              Text(
                persona.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description (max 3 lines, takes remaining space)
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    persona.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Vote counts (no buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${persona.upvotes}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.thumb_down_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${persona.downvotes}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
