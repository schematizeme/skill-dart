---
description: schematize-dart — carrega à força TODO o corpo normativo do piso de Dart e passa a aplicá-lo nesta sessão.
---
Carregue **agora** o corpo normativo da skill `schematize-dart` (`.claude/skills/schematize-dart/references/*.md`):

- `piso.md` — opcional como tipo (**force-unwrap é `fatalError` adiado**), concorrência estruturada
  (Dart 6 strict, `@MainActor` só na UI, `Sendable`, cancelamento cooperativo, **reentrância do
  actor**), ARC e ciclo de retenção, erro tipado, segurança do cliente, teste.
- `plataforma.md` — DartPM e `Package.resolved`, CI com simulador fixado, assinatura em cofre,
  `@available`, server-side Dart fora do rol, interop Obj-C/C.
- `stack-versoes.md` — anexo volátil, com data **e a ressalva de alcance** (a toolchain Flutter não roda na
  máquina de referência do catálogo).

Depois, rode o gate: `bash .claude/skills/schematize-dart/scripts/check-dart.sh .`
E lembre: no que é de **app**, quem manda é a **`schematize-mobile`**.
