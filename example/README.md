# adaptive_actions_example

A showcase of Material and Cupertino adaptive action regions using Flutter
3.47 and the standalone `material_ui` / `cupertino_ui` packages.

From the repository root:

```shell
fvm use 3.47.9
cd example
fvm flutter pub get
fvm flutter run
```

The controls switch renderers, themes, text direction, action language, layout,
and animation settings. Both renderers share the same action model and command
handling. App shells, themes, localization delegates, and custom builders all
use the standalone UI packages. Material/Cupertino SDK imports are not used.

Run `make check` from the repository root to analyze and test the package and
this example together.
