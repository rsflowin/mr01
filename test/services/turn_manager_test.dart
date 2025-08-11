import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../lib/services/turn_manager.dart';

void main() {
  group('TurnManager Tests', () {
    late TurnManager turnManager;

    setUp(() {
      turnManager = TurnManager();
    });

    group('Turn Transition Message', () {
      test('getTurnTransitionMessage returns correct message', () {
        const expectedMessage = "Others in the maze are moving...";
        expect(turnManager.getTurnTransitionMessage(), equals(expectedMessage));
      });
    });

    group('Transition Duration Validation', () {
      test('validateTransitionParameters accepts valid durations', () {
        // Valid durations
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 1000),
          ),
          isTrue,
        );
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 2500),
          ),
          isTrue,
        );
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 500),
          ),
          isTrue,
        );
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 5000),
          ),
          isTrue,
        );
      });

      test('validateTransitionParameters rejects invalid durations', () {
        // Too short
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 400),
          ),
          isFalse,
        );

        // Too long
        expect(
          turnManager.validateTransitionParameters(
            duration: const Duration(milliseconds: 6000),
          ),
          isFalse,
        );
      });

      test('validateTransitionParameters accepts null duration', () {
        expect(turnManager.validateTransitionParameters(), isTrue);
      });
    });

    group('Recommended Duration', () {
      test(
        'getRecommendedDuration returns correct duration for fast preference',
        () {
          final duration = turnManager.getRecommendedDuration(
            playerPreference: 'fast',
          );
          expect(duration, equals(const Duration(milliseconds: 1000)));
        },
      );

      test(
        'getRecommendedDuration returns correct duration for slow preference',
        () {
          final duration = turnManager.getRecommendedDuration(
            playerPreference: 'slow',
          );
          expect(duration, equals(const Duration(milliseconds: 2000)));
        },
      );

      test(
        'getRecommendedDuration returns default duration for normal preference',
        () {
          final duration = turnManager.getRecommendedDuration(
            playerPreference: 'normal',
          );
          expect(duration, equals(const Duration(milliseconds: 1500)));
        },
      );

      test(
        'getRecommendedDuration returns default duration for unknown preference',
        () {
          final duration = turnManager.getRecommendedDuration(
            playerPreference: 'unknown',
          );
          expect(duration, equals(const Duration(milliseconds: 1500)));
        },
      );
    });

    group('Transition State Creation', () {
      test(
        'createTransitionState creates correct state for active transition',
        () {
          final state = turnManager.createTransitionState(
            isActive: true,
            message: 'Custom message',
            progress: 0.5,
          );

          expect(state['isActive'], isTrue);
          expect(state['message'], equals('Custom message'));
          expect(state['progress'], equals(0.5));
          expect(state['startTime'], isA<DateTime>());
        },
      );

      test(
        'createTransitionState creates correct state for inactive transition',
        () {
          final state = turnManager.createTransitionState(isActive: false);

          expect(state['isActive'], isFalse);
          expect(state['message'], equals("Others in the maze are moving..."));
          expect(state['progress'], equals(1.0));
          expect(state['startTime'], isNull);
        },
      );

      test('createTransitionState uses default message when not provided', () {
        final state = turnManager.createTransitionState(isActive: true);

        expect(state['message'], equals("Others in the maze are moving..."));
      });
    });

    group('Animation Configuration', () {
      test('createAnimationConfig returns correct configuration structure', () {
        const customDuration = Duration(milliseconds: 2000);
        final config = turnManager.createAnimationConfig(
          duration: customDuration,
        );

        expect(config['duration'], equals(customDuration));
        expect(
          config['fadeInDuration'],
          equals(const Duration(milliseconds: 400)),
        );
        expect(
          config['holdDuration'],
          equals(const Duration(milliseconds: 1200)),
        );
        expect(
          config['fadeOutDuration'],
          equals(const Duration(milliseconds: 400)),
        );
        expect(config['curve'], equals('easeInOut'));
      });

      test('createAnimationConfig uses default duration when not provided', () {
        final config = turnManager.createAnimationConfig();

        expect(config['duration'], equals(const Duration(milliseconds: 1500)));
        expect(
          config['fadeInDuration'],
          equals(const Duration(milliseconds: 300)),
        );
        expect(
          config['holdDuration'],
          equals(const Duration(milliseconds: 900)),
        );
        expect(
          config['fadeOutDuration'],
          equals(const Duration(milliseconds: 300)),
        );
      });
    });

    group('Turn Transition Flow', () {
      test('waitForTransition completes after specified duration', () async {
        final stopwatch = Stopwatch()..start();
        const testDuration = Duration(milliseconds: 100);

        await turnManager.waitForTransition(testDuration);

        stopwatch.stop();
        // Allow for some timing variance in test environment
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(150));
      });

      test('returnToMovementPhase calls callback when provided', () {
        bool callbackCalled = false;

        turnManager.returnToMovementPhase(
          onReturnToMovement: () {
            callbackCalled = true;
          },
        );

        expect(callbackCalled, isTrue);
      });

      test('returnToMovementPhase does not throw when callback is null', () {
        expect(() => turnManager.returnToMovementPhase(), returnsNormally);
      });
    });

    group('Full Turn Cycle', () {
      test('processTurnCycle completes successfully with callbacks', () async {
        bool transitionStartCalled = false;
        bool transitionCompleteCalled = false;
        bool returnToMovementCalled = false;

        await turnManager.processTurnCycle(
          onTransitionStart: () {
            transitionStartCalled = true;
          },
          onTransitionComplete: () {
            transitionCompleteCalled = true;
          },
          onReturnToMovement: () {
            returnToMovementCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        expect(transitionStartCalled, isTrue);
        expect(transitionCompleteCalled, isTrue);
        expect(returnToMovementCalled, isTrue);
      });

      test(
        'processTurnCycle completes successfully without callbacks',
        () async {
          expect(
            () => turnManager.processTurnCycle(
              duration: const Duration(milliseconds: 50),
            ),
            returnsNormally,
          );
        },
      );

      test('displayTurnTransition calls callbacks correctly', () async {
        bool transitionStartCalled = false;
        bool transitionCompleteCalled = false;

        await turnManager.displayTurnTransition(
          onTransitionStart: () {
            transitionStartCalled = true;
          },
          onTransitionComplete: () {
            transitionCompleteCalled = true;
          },
          duration: const Duration(milliseconds: 50),
        );

        expect(transitionStartCalled, isTrue);
        expect(transitionCompleteCalled, isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles null callbacks gracefully', () async {
        expect(
          () => turnManager.displayTurnTransition(
            onTransitionStart: null,
            onTransitionComplete: null,
          ),
          returnsNormally,
        );
      });

      test('handles zero duration gracefully', () async {
        final stopwatch = Stopwatch()..start();

        await turnManager.waitForTransition(Duration.zero);

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(10));
      });

      test('animation configuration handles very short durations', () {
        const shortDuration = Duration(milliseconds: 100);
        final config = turnManager.createAnimationConfig(
          duration: shortDuration,
        );

        expect(
          config['fadeInDuration'],
          equals(const Duration(milliseconds: 20)),
        );
        expect(
          config['holdDuration'],
          equals(const Duration(milliseconds: 60)),
        );
        expect(
          config['fadeOutDuration'],
          equals(const Duration(milliseconds: 20)),
        );
      });
    });
  });
}
