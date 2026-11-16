# Documentation

<img src="assets/divider.svg" alt="" width="100%"/>

| Guide | Read it when |
| --- | --- |
| **[SETUP.md](SETUP.md)** | You are setting the project up on a new machine, or something does not start |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | You want to understand the layers, or add a feature |
| **[ROLES_AND_ACCESS.md](ROLES_AND_ACCESS.md)** | You are adding a role, a capability or a guarded page |
| **[SIGN_IN_PROVIDERS.md](SIGN_IN_PROVIDERS.md)** | You are setting up Google, Facebook or GitHub sign in |
| **[MAPS_AND_PLACES.md](MAPS_AND_PLACES.md)** | You are creating Google Maps keys, or maps and search misbehave |
| **[THEMING.md](THEMING.md)** | You are adding a theme, a texture or a font |
| **[../config/env/README.md](../config/env/README.md)** | You are filling in an environment file |

New to the project? Read the [README](../README.md) first, then [SETUP.md](SETUP.md), then [ARCHITECTURE.md](ARCHITECTURE.md). That is about twenty minutes and it is enough to start changing things safely.

## The pictures

Everything in `assets/` is plain SVG, drawn by [`tool/readme_assets.py`](../tool/readme_assets.py) with nothing but the Python standard library. The fonts the pictures use are small subsets kept in [`tool/fonts`](../tool/fonts), embedded into each file so they look the same on GitHub as anywhere else. The colour themes, the roles grid and the code statistics are **read from the real source files**, so they stay true to the code. After a large change, refresh them:

```bash
python3 tool/readme_assets.py
```

The pictures move, and all of it is plain CSS: a scan across the banner, packets and lit layers on the architecture drawing, a row sweep on the roles table, a theme stepper with a **T** key, and a walk through the setup steps. A device that asks for reduced motion shows every picture still.

| File | Shows |
| --- | --- |
| `banner.svg`, `divider.svg` | The header and the section dividers |
| `architecture.svg`, `auth-flow.svg` | How a request travels and how tokens refresh |
| `roles.svg` | Roles against capabilities, from `role_registry.dart` |
| `platforms.svg` | What works on each platform |
| `themes.svg`, `patterns.svg` | The palettes and textures, from `palette.dart` |
| `stats-features.svg`, `stats-layers.svg` | Lines of Dart per feature and per layer |
| `stack.svg`, `setup.svg` | The libraries used, and the setup steps |

The animations are CSS and SMIL inside the SVG, so they play on GitHub with no scripts. The CSS ones stop when the viewer asks for reduced motion.
