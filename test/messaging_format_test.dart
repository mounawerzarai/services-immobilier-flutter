import 'package:flutter_test/flutter_test.dart';
import 'package:services_immobilier/data/models/conversation.dart';
import 'package:services_immobilier/features/messaging/format.dart';

void main() {
  final now = DateTime(2026, 11, 17, 15, 30);

  test('formatConversationDate', () {
    expect(formatConversationDate(DateTime(2026, 11, 17, 9, 5), now), '09:05');
    expect(formatConversationDate(DateTime(2026, 11, 16, 23, 0), now), 'Hier');
    expect(formatConversationDate(DateTime(2026, 11, 3, 8, 0), now), '03/11/2026');
    expect(formatConversationDate(null, now), '');
  });

  test('formatDayLabel', () {
    expect(formatDayLabel(DateTime(2026, 11, 17, 1), now), 'Aujourd’hui');
    expect(formatDayLabel(DateTime(2026, 11, 16, 1), now), 'Hier');
    expect(formatDayLabel(DateTime(2026, 11, 2), now), '2 novembre 2026');
  });

  test('conversation non lue', () {
    final c = Conversation(
      id: 'c',
      participants: const ['a', 'b'],
      lastSenderId: 'b',
      updatedAt: DateTime(2026, 11, 17, 10),
      readAt: {'a': DateTime(2026, 11, 17, 9)},
    );
    expect(c.isUnreadFor('a'), isTrue);
    expect(c.isUnreadFor('b'), isFalse);
    expect(c.otherOf('a'), 'b');
  });
}
