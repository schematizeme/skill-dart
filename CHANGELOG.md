# Changelog — schematize-dart

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [0.1.0] — 2026-08-21

Primeira versão. A `schematize-mobile` promete escolha *"nativo vs cross por fit + ADR"* e **não havia skill por trás de nenhuma das opções** (vistoria de 2026-08-21). Esta é a peça **cross**, publicada no mesmo marco que `schematize-swift`, `schematize-kotlin` e o conserto da `schematize-mobile` (v0.3.0).

### Adicionado
- **`references/piso.md`** — null safety que **não se devolve** (`!` desliga exatamente a verificação pela qual você pagou a migração; `late` é promessa cujo erro **não diz mais que um null**; `dynamic` transforma erro de tipo em `NoSuchMethodError` em produção); **assíncrono** (`Future` sem `await` é **ordem de execução que ninguém escreveu**, e o erro dele vira `unhandled exception` global; stream sem `cancel()` vaza **e** dispara `setState` depois da tela morrer; CPU pesado fora da UI thread, porque o sintoma é **jank, não erro**); **Flutter** (`BuildContext` depois de `await` sem `mounted` — a armadilha nº 1; `const`; **`Key` em lista dinâmica**, que é o bug "o checkbox marcou a linha de cima"); erro **com stack trace**; segurança do cliente; teste (com `pumpAndSettle` que **não** é sinônimo de "esperou").
- **`references/plataforma.md`** — `pubspec.lock` commitado **em aplicação** (em package publicado, não), SDK e Flutter fixados, **dependência como superfície** (*plugin com código nativo dobra a superfície*: traz Kotlin/Swift/C que passa a ser seu no build, no crash e na revisão da loja), alvos com ADR (`dart:io` não existe no web e `dart:html` não existe no mobile — **compile todos os alvos no CI**), release com ofuscação e **mapa de símbolos guardado**.
- **`scripts/check-dart.sh`** + **`check-dart.test.sh`** (**9 casos**, 7 vermelhos): `!`, `late`, `dynamic`, `catch` vazio, `print`, `context` com `await` e sem `mounted`, `.listen(` sem `cancel()`, credencial em `shared_preferences`, WebView com JS irrestrito — e, no projeto: **`pubspec.lock` ausente em aplicação**, `environment:` ausente, **`analysis_options.yaml` ausente** e os lints do piso não declarados.

### Honestidade sobre o alcance
- A toolchain Flutter **não roda na máquina de referência** do catálogo. O gate é **textual** e **diz isso na saída**; onde houver `flutter analyze`, **é ele que manda**. Os números moram no anexo volátil, com a mesma ressalva.
