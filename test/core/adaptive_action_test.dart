import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const saveMetadata = ActionMetadata(
    label: 'Save',
    subtitle: 'Current document',
    tooltip: 'Save document',
    semanticLabel: 'Save current document',
    iconKey: 'save',
  );

  AdaptiveAction<String> action(
    String id, {
    String? payload,
    bool isEnabled = true,
  }) => AdaptiveAction.action(
    id: ActionId(id),
    metadata: ActionMetadata(label: id),
    payload: payload ?? id,
    isEnabled: isEnabled,
  );

  group('ActionMetadata', () {
    test('has platform-neutral defaults and value equality', () {
      const first = ActionMetadata(label: 'Save');
      const second = ActionMetadata(label: 'Save');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.subtitle, isNull);
      expect(first.tooltip, isNull);
      expect(first.semanticLabel, isNull);
      expect(first.iconKey, isNull);
      expect(first.isDestructive, isFalse);
    });

    test('includes all fields in equality', () {
      expect(
        saveMetadata,
        const ActionMetadata(
          label: 'Save',
          subtitle: 'Current document',
          tooltip: 'Save document',
          semanticLabel: 'Save current document',
          iconKey: 'save',
        ),
      );
      expect(
        saveMetadata,
        isNot(
          const ActionMetadata(
            label: 'Save',
            subtitle: 'Another document',
            tooltip: 'Save document',
            semanticLabel: 'Save current document',
            iconKey: 'save',
          ),
        ),
      );
      expect(
        saveMetadata,
        isNot(
          const ActionMetadata(
            label: 'Save',
            subtitle: 'Current document',
            tooltip: 'Save document',
            semanticLabel: 'Save current document',
            iconKey: 'save',
            isDestructive: true,
          ),
        ),
      );
      expect(saveMetadata.toString(), contains('subtitle: Current document'));
    });
  });

  group('AdaptiveAction', () {
    test('represents invokable, menu, and composite nodes', () {
      final leaf = AdaptiveAction<String>.action(
        id: ActionId('save'),
        metadata: saveMetadata,
        payload: 'save-command',
        isEnabled: false,
      );
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('file'),
        metadata: const ActionMetadata(label: 'File'),
        children: [leaf],
      );
      final composite = AdaptiveAction<String>.composite(
        id: ActionId('recent'),
        metadata: const ActionMetadata(label: 'Recent'),
        payload: 'open-most-recent',
        children: [leaf],
      );

      expect(leaf.payload, 'save-command');
      expect(leaf.children, isEmpty);
      expect(leaf.isEnabled, isFalse);
      expect(leaf.isInvokable, isTrue);
      expect(menu.payload, isNull);
      expect(menu.isInvokable, isFalse);
      expect(menu.children, [leaf]);
      expect(composite.payload, 'open-most-recent');
      expect(composite.children, [leaf]);
    });

    test('preserves arbitrary depth and declaration order', () {
      final first = action('first');
      final second = action('second');
      final submenu = AdaptiveAction<String>.menu(
        id: ActionId('submenu'),
        metadata: const ActionMetadata(label: 'Submenu'),
        children: [first, second],
      );
      final root = AdaptiveAction<String>.menu(
        id: ActionId('root'),
        metadata: const ActionMetadata(label: 'Root'),
        children: [submenu],
      );

      expect((root.children.single as AdaptiveAction<String>).children, [
        first,
        second,
      ]);
    });

    test('preserves menu dividers without giving them action semantics', () {
      final first = action('first');
      final second = action('second');
      const divider = AdaptiveMenuDivider<String>();
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [first, divider, second],
      );

      expect(menu.children, [first, divider, second]);
      expect(divider, const AdaptiveMenuDivider<String>());
      expect(divider.hashCode, const AdaptiveMenuDivider<String>().hashCode);
      expect(divider.showInPrimary, isTrue);
      expect(divider.showInMenu, isTrue);
      expect(
        divider.toString(),
        'AdaptiveMenuDivider<String>(showInPrimary: true, showInMenu: true)',
      );
      expect(ActionCollection<String>(roots: [menu]).roots.single, same(menu));
    });

    test('defensively copies and exposes an unmodifiable child list', () {
      final first = action('first');
      final input = <AdaptiveAction<String>>[first];
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: input,
      );

      input.add(action('second'));

      expect(menu.children, [first]);
      expect(() => menu.children.add(action('third')), throwsUnsupportedError);
    });

    test('rejects empty or divider-only child lists', () {
      expect(
        () => AdaptiveAction<String>.menu(
          id: ActionId('menu'),
          metadata: const ActionMetadata(label: 'Menu'),
          children: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveAction<String>.composite(
          id: ActionId('composite'),
          metadata: const ActionMetadata(label: 'Composite'),
          payload: 'invoke',
          children: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveAction<String>.menu(
          id: ActionId('divider-only'),
          metadata: const ActionMetadata(label: 'Divider only'),
          children: const [AdaptiveMenuDivider<String>()],
        ),
        throwsArgumentError,
      );
    });

    test('allows a divider to be hidden in both targets', () {
      const divider = AdaptiveMenuDivider<String>(
        showInPrimary: false,
        showInMenu: false,
      );
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [action('first'), divider, action('second')],
      );

      expect(menu.children, contains(divider));
      expect(divider.showInPrimary, isFalse);
      expect(divider.showInMenu, isFalse);
    });

    test('has structural equality and hashing', () {
      AdaptiveAction<String> buildTree() => AdaptiveAction.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [action('first'), action('second')],
      );

      final first = buildTree();
      final second = buildTree();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(action('menu')));
    });
  });
}
