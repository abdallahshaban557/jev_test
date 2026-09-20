import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jev_dart/jev_dart.dart';
import 'package:jev_choices/choice_service.dart';

void main() {
  for (final option in ServiceOption.values) {
    test('sends constrained choices and returns ${option.name}', () async {
      final service = ChoiceService(
        clientFactory: (key) => TypeSafeClient(
          apiKey: key,
          allowBrowser: true,
          closeClient: true,
          httpClient: MockClient((request) async {
            expect(
              request.url.toString(),
              'https://api.typesafe.ai/v1/systemone',
            );
            expect(request.headers['Authorization'], 'Bearer test-key');
            final body = jsonDecode(request.body) as Map;
            expect(body['state']['current_question'], 'My question');
            expect(body['state']['conversation'], hasLength(1));
            expect(body['questions']['service']['type'], 'choice');
            expect(
              (body['questions']['service']['criteria'] as Map).keys,
              unorderedEquals(['stripe', 'posthog', 'clerk']),
            );
            return http.Response(
              jsonEncode({
                'model': 'jev-latest',
                'answers': {
                  'service': {
                    'type': 'choice',
                    'choice': option.name,
                    'confidence': 0.9,
                    'probabilities': {option.name: 0.9},
                  },
                },
                'usage': {'input_tokens': 10, 'output_tokens': 5},
              }),
              200,
            );
          }),
        ),
      );
      expect(
        await service.select(
          apiKey: 'test-key',
          prompt: 'My question',
          history: [
            {'role': 'user', 'content': 'Previous question'},
          ],
        ),
        option,
      );
    });
  }
  test(
    'authentication failure is surfaced without inventing a choice',
    () async {
      final service = ChoiceService(
        clientFactory: (key) => TypeSafeClient(
          apiKey: key,
          allowBrowser: true,
          closeClient: true,
          httpClient: MockClient(
            (_) async => http.Response('{"error":"Invalid key"}', 401),
          ),
        ),
      );
      await expectLater(
        service.select(apiKey: 'bad', prompt: 'Pay', history: []),
        throwsA(isA<AuthenticationException>()),
      );
    },
  );
}
