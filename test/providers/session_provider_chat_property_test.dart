import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/message_model.dart';

/// **Feature: tahap-6-chat-room, Property 10: GET messages response parsing extracts data and meta correctly**
///
/// **Validates: Requirements 9.2**
///
/// For any valid paginated response envelope from GET /api/sessions/:id/messages,
/// the provider shall correctly extract the message list from response.data['data']
/// and pagination metadata from response.data['meta'].
///
/// This tests the pure parsing logic of fetchMessages by simulating valid
/// paginated responses with random message lists and verifying:
/// 1. The number of parsed messages matches the input list length
/// 2. All parsed items are valid MessageModel instances
/// 3. Messages are sorted ascending by createdAt after parsing
void main() {
  group(
    'Property 10: GET messages response parsing extracts data and meta correctly',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random UUID-like string.
      String generateRandomId(Random rng) {
        const chars = 'abcdef0123456789';
        return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
      }

      /// Generate a random non-empty content string.
      String generateRandomContent(Random rng) {
        const words = [
          'Halo',
          'Apa kabar?',
          'Saya merasa sedih hari ini',
          'Terima kasih sudah mendengarkan',
          'Bagaimana menurutmu?',
          'Saya ingin cerita',
          'Hari ini cukup berat',
          'Saya senang bisa ngobrol',
        ];
        final wordCount = 1 + rng.nextInt(3);
        return List.generate(
          wordCount,
          (_) => words[rng.nextInt(words.length)],
        ).join(' ');
      }

      /// Generate a random DateTime with millisecond precision in UTC.
      DateTime generateRandomDateTime(Random rng) {
        // Generate timestamps between 2023-01-01 and 2025-12-31
        // Use smaller range to stay within nextInt's 2^32 limit
        final baseMs = DateTime(2023, 1, 1).millisecondsSinceEpoch;
        final rangeDays = 3 * 365; // ~3 years in days
        final offsetMs = rng.nextInt(rangeDays) * 86400000 +
            rng.nextInt(86400000); // random day + random ms within day
        return DateTime.fromMillisecondsSinceEpoch(
          baseMs + offsetMs,
          isUtc: true,
        );
      }

      /// Generate a single valid message JSON map.
      Map<String, dynamic> generateMessageJson(Random rng, String sessionId) {
        final role = rng.nextBool() ? 'user' : 'model';
        return {
          'id': generateRandomId(rng),
          'sessionId': sessionId,
          'role': role,
          'content': generateRandomContent(rng),
          'createdAt': generateRandomDateTime(rng).toIso8601String(),
        };
      }

      /// Generate a valid paginated response envelope with N messages.
      /// Returns the full response.data map as the backend would return it.
      Map<String, dynamic> generatePaginatedResponse(
        Random rng, {
        int? messageCount,
      }) {
        final sessionId = generateRandomId(rng);
        final count = messageCount ?? rng.nextInt(50); // 0-49 messages
        final messages = List.generate(
          count,
          (_) => generateMessageJson(rng, sessionId),
        );

        // Shuffle messages to simulate backend returning in any order
        messages.shuffle(rng);

        final total = count + rng.nextInt(100); // total >= count
        final page = 1;
        final limit = 50;
        final totalPages = (total / limit).ceil().clamp(1, 100);

        return {
          'success': true,
          'message': 'Messages retrieved successfully',
          'data': messages,
          'meta': {
            'total': total,
            'page': page,
            'limit': limit,
            'totalPages': totalPages,
          },
        };
      }

      /// Simulates the fetchMessages parsing logic from SessionProvider.
      ///
      /// This replicates the exact parsing path in SessionProvider.fetchMessages:
      /// 1. Extract response.data['data'] as List
      /// 2. Map each item to MessageModel.fromJson
      /// 3. Sort ascending by createdAt
      ({
        List<MessageModel> messages,
        Map<String, dynamic> meta,
      }) simulateFetchMessagesParsing(Map<String, dynamic> responseData) {
        // Extract data list (same as provider does)
        final data = responseData['data'] as List<dynamic>;
        var messages = data
            .map((json) =>
                MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort ascending by createdAt (same as provider does)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Extract meta
        final meta = responseData['meta'] as Map<String, dynamic>;

        return (messages: messages, meta: meta);
      }

      test(
        'For any valid paginated response with N messages, parsing produces '
        'exactly N MessageModel instances ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(random);
            final inputMessages = responseData['data'] as List;
            final expectedCount = inputMessages.length;

            final result = simulateFetchMessagesParsing(responseData);

            expect(
              result.messages.length,
              equals(expectedCount),
              reason: 'Iteration $i: parsed messages count should be '
                  '$expectedCount, got ${result.messages.length}',
            );
          }
        },
      );

      test(
        'For any valid paginated response, all parsed items are valid '
        'MessageModel instances with non-empty fields ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(random);
            final result = simulateFetchMessagesParsing(responseData);

            for (var j = 0; j < result.messages.length; j++) {
              final msg = result.messages[j];

              expect(
                msg.id.isNotEmpty,
                isTrue,
                reason: 'Iteration $i, message $j: id should be non-empty',
              );
              expect(
                msg.sessionId.isNotEmpty,
                isTrue,
                reason:
                    'Iteration $i, message $j: sessionId should be non-empty',
              );
              expect(
                msg.role == 'user' || msg.role == 'model',
                isTrue,
                reason: 'Iteration $i, message $j: role should be "user" or '
                    '"model", got "${msg.role}"',
              );
              expect(
                msg.content.isNotEmpty,
                isTrue,
                reason:
                    'Iteration $i, message $j: content should be non-empty',
              );
            }
          }
        },
      );

      test(
        'For any valid paginated response, parsed messages are sorted '
        'ascending by createdAt ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(random);
            final result = simulateFetchMessagesParsing(responseData);

            for (var j = 1; j < result.messages.length; j++) {
              final prev = result.messages[j - 1].createdAt;
              final curr = result.messages[j].createdAt;

              expect(
                prev.compareTo(curr) <= 0,
                isTrue,
                reason: 'Iteration $i: messages should be sorted ascending '
                    'by createdAt. Message at index ${j - 1} ($prev) should '
                    'be <= message at index $j ($curr)',
              );
            }
          }
        },
      );

      test(
        'For any valid paginated response, meta fields are correctly extracted '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(random);
            final result = simulateFetchMessagesParsing(responseData);

            final expectedMeta =
                responseData['meta'] as Map<String, dynamic>;

            expect(
              result.meta['total'],
              equals(expectedMeta['total']),
              reason: 'Iteration $i: meta.total should match input',
            );
            expect(
              result.meta['page'],
              equals(expectedMeta['page']),
              reason: 'Iteration $i: meta.page should match input',
            );
            expect(
              result.meta['limit'],
              equals(expectedMeta['limit']),
              reason: 'Iteration $i: meta.limit should match input',
            );
            expect(
              result.meta['totalPages'],
              equals(expectedMeta['totalPages']),
              reason: 'Iteration $i: meta.totalPages should match input',
            );
          }
        },
      );

      test(
        'For any valid paginated response, each parsed MessageModel matches '
        'its source JSON data ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(random);
            final inputMessages =
                (responseData['data'] as List).cast<Map<String, dynamic>>();
            final result = simulateFetchMessagesParsing(responseData);

            // Build a lookup by id to verify each message was parsed correctly
            final parsedById = {
              for (final msg in result.messages) msg.id: msg,
            };

            for (final inputJson in inputMessages) {
              final id = inputJson['id'] as String;
              final parsed = parsedById[id];

              expect(
                parsed,
                isNotNull,
                reason: 'Iteration $i: message with id "$id" should be '
                    'present in parsed results',
              );

              expect(
                parsed!.sessionId,
                equals(inputJson['sessionId']),
                reason: 'Iteration $i: sessionId should match for id "$id"',
              );
              expect(
                parsed.role,
                equals(inputJson['role']),
                reason: 'Iteration $i: role should match for id "$id"',
              );
              expect(
                parsed.content,
                equals(inputJson['content']),
                reason: 'Iteration $i: content should match for id "$id"',
              );
              expect(
                parsed.createdAt,
                equals(DateTime.parse(inputJson['createdAt'] as String)),
                reason: 'Iteration $i: createdAt should match for id "$id"',
              );
            }
          }
        },
      );

      test(
        'Empty message list (0 messages) is correctly parsed '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final responseData = generatePaginatedResponse(
              random,
              messageCount: 0,
            );
            final result = simulateFetchMessagesParsing(responseData);

            expect(
              result.messages.isEmpty,
              isTrue,
              reason: 'Iteration $i: empty response should produce '
                  'empty messages list',
            );

            // Meta should still be extractable
            expect(result.meta['total'], isA<int>());
            expect(result.meta['page'], isA<int>());
            expect(result.meta['limit'], isA<int>());
            expect(result.meta['totalPages'], isA<int>());
          }
        },
      );
    },
  );
}
