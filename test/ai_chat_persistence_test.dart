import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/models/ai_chat_message.dart';
import 'package:jnova/services/ai_chat_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    AIChatService.instance.clearMemory();
    await AIChatService.instance.resetChat();
  });

  tearDown(() async {
    AIChatService.instance.clearMemory();
  });

  group('AIChatService Persistence Tests', () {
    test('Default chat messages are loaded when database is fresh', () async {
      final messages = await AIChatService.instance.loadMessages();
      expect(messages.isNotEmpty, isTrue);
      expect(messages.first.id, 'm1');
      expect(messages.first.isUser, isFalse);
    });

    test('New messages persist and reload across sessions', () async {
      final initialMessages = await AIChatService.instance.loadMessages();
      final initialCount = initialMessages.length;

      const userText = 'Halo, saya mencari drum elektrik untuk kamar tidur.';
      final newMsg = AIChatMessage(
        id: 'test_msg_101',
        isUser: true,
        text: userText,
        time: '15:30',
      );

      await AIChatService.instance.addMessage(newMsg);

      // Verify in current memory
      expect(AIChatService.instance.messages.length, initialCount + 1);
      expect(AIChatService.instance.messages.last.text, userText);

      // Simulate leaving the chat page and opening it again (clear in-memory state)
      AIChatService.instance.clearMemory();

      // Reload from database
      final reloaded = await AIChatService.instance.loadMessages();
      expect(reloaded.length, initialCount + 1);
      expect(reloaded.any((m) => m.id == 'test_msg_101' && m.text == userText), isTrue);
    });

    test('Resetting chat removes user messages and restores defaults', () async {
      const customMsg = AIChatMessage(
        id: 'temp_msg',
        isUser: true,
        text: 'Ini pesan sementara',
        time: '16:00',
      );
      await AIChatService.instance.addMessage(customMsg);

      // Reset
      await AIChatService.instance.resetChat();

      // Ensure custom message is gone
      final reloaded = await AIChatService.instance.loadMessages(forceReload: true);
      expect(reloaded.any((m) => m.id == 'temp_msg'), isFalse);
      expect(reloaded.first.id, 'm1');
    });
  });
}
