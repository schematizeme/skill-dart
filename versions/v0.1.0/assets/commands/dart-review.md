---
description: schematize-dart — revisa Dart contra o piso: roda o gate e depois lê o que a máquina não lê (assíncrono, Flutter, projeto, fronteira com a mobile)
argument-hint: "[arquivo.dart ou diretório]"
---

# /dart-review

## 1. A máquina

```bash
bash .claude/skills/schematize-dart/scripts/check-dart.sh .
# onde houver toolchain, SÃO ELES que mandam:
dart build -Xdartc -warnings-as-errors && dart test
dartlint --strict   # ou dart-format lint --strict
```

`0` passa · `1` reprova · `2` **nada para verificar** (não é aprovação). O gate é **textual** e diz
isso na saída.

## 2. O que a máquina não lê

- **Concorrência:** o módulo está em **Dart 6 mode**? Há `@MainActor` no que **não** toca UI (que
  serializa o app)? Toda operação longa **checa cancelamento**? Depois de cada `await` dentro de um
  `actor`, a invariante foi **relida** (reentrância)?
- **Flutter:** todo uso de `context` depois de `await` tem `if (!mounted) return;`? há `Key` nas
  listas dinâmicas? o que dá para ser `const` é `const`? nada de lógica no `build`?
- **Null safety:** cada `!` restante tem invariante **real**? algum `late` que é só conserto de nulo?
  algum `dynamic` que dá para tipar?
- **Erro:** o `catch` captura **o tipo** e guarda o **stack trace** (`on X catch (e, s)`)? nada de
  `print` como tratamento?
- **Fronteira:** o que é de app (offline, IAM, push, loja) está seguindo a **`schematize-mobile`**,
  não uma segunda versão da regra escrita aqui?
- **Segredo:** nada no bundle (nem via `--dart-define`); credencial em `flutter_secure_storage`;
  log sem PII/token.

## 3. Feche

Achado vira correção no mesmo PR ou item de checklist com dono. Mexeu no gate? rode o vermelho:
`bash scripts/check-dart.test.sh` (9 casos).
