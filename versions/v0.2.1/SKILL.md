---
name: schematize-dart
metadata:
  version: 0.2.1
description: O piso de DART/FLUTTER da casa. Rege null safety que não se devolve (**`!` desliga a verificação pela qual você pagou a migração**; `late` não é conserto de nulo incômodo; `dynamic` vira `NoSuchMethodError` em produção); assíncrono (**`Future` sem `await` é ordem de execução que ninguém escreveu**; stream sem `cancel()` é vazamento que ainda dispara `setState` depois da tela morrer; CPU pesado sai da UI thread ou vira jank); Flutter (**`BuildContext` depois de `await` sem `mounted`** é a armadilha nº 1; `const` onde der; `Key` em lista dinâmica); erro com stack trace, nunca `catch (e) {}`; segredo fora do bundle e `shared_preferences` não é cofre; `pubspec.lock` commitado em aplicação e os lints do piso **explícitos** — herdar `flutter_lints` não basta. Traz gate executável.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de Dart/Flutter da casa (schematize-dart)

Recorte de **linguagem e framework**. A base agnóstica é a **`schematize-engineering`**; o piso de
**app** é da **`schematize-mobile`** — e, no que é de app, **ela manda**.

**Versão:** skill `schematize-dart` v0.2.1. Changelog em `CHANGELOG.md`.

## Por que ela nasceu

A `schematize-mobile` promete escolha *"nativo vs cross por fit + ADR"* e **não havia skill por trás
de nenhuma das opções** (vistoria de 2026-08-21). Esta é a peça **cross** — publicada junto com
`schematize-swift`, `schematize-kotlin` e o conserto da própria `schematize-mobile`, para que a
escolha por fit passe a ter as duas respostas sustentadas.

## Comandos (Claude Code)

| Comando | O que faz |
|---|---|
| `/dart-help` | lista os comandos |
| `/dart-load` | carrega à força o corpo normativo (piso, plataforma) |
| `/dart-review` | revisa `.dart` e o projeto contra o piso: roda o gate e lê o que a máquina não lê |
| `/dart-claude` | cria/mescla o `CLAUDE.md` sempre-on na raiz do repo |
| `/dart-cc` · `/dart-handoff` | context compact / handoff arquivado |

## Como usar

1. **O que é de app é da `schematize-mobile`**.
2. **Rode o gate:** `bash scripts/check-dart.sh .` — `0` passa · `1` reprova · `2` **nada para
   verificar** (não é aprovação). Ele é **textual**: onde houver `flutter analyze`, **é ele que
   manda**.
3. **Piso de linguagem** em `references/piso.md`; **build, dependência e alvos** em
   `references/plataforma.md`.

Mapa de references:

| Tarefa | Reference |
|---|---|
| Null safety, assíncrono (`await`, stream, isolate), Flutter (`mounted`, `const`, `Key`, `dispose`), erro com stack trace, segurança do cliente, teste | `references/piso.md` |
| `pubspec.lock`, SDK fixado, `flutter analyze` como gate, dependência como superfície (plugin nativo dobra a superfície), alvos com ADR, release (ofuscação, tamanho) | `references/plataforma.md` |
| Versões, ferramental e **os lints que o piso exige ligados**, com data **e a ressalva de que a toolchain não roda na máquina de referência** | `references/stack-versoes.md` |

## Pisos inegociáveis (vetam o atalho)

1. **`!` (bang) é VETADO** em produção — ele desliga exatamente a verificação pela qual você pagou a
   migração do null safety.
2. **`late` não é conserto de nulo incômodo**, e `dynamic` é o buraco no sistema de tipos (vira
   `NoSuchMethodError` em produção).
3. **Todo `Future` é aguardado** ou `unawaited(...)` **explícito** — esquecer produz ordem de
   execução que ninguém escreveu, e o erro vira `unhandled exception` global.
4. **Stream tem `cancel()` no `dispose()`**; `Timer`/`AnimationController` também. Sem isso é
   vazamento **e** `setState` depois da tela morrer.
5. **`BuildContext` depois de `await` exige `if (!mounted) return;`** — a armadilha nº 1 do Flutter.
6. **CPU pesado fora da UI thread** (`compute`/`Isolate`): o sintoma de ignorar é jank, não erro.
7. **Erro com stack trace** (`on X catch (e, s)`); `catch (e) {}` e `print` como tratamento são
   VETADOS.
8. **Segredo nunca no bundle** (`--dart-define` inclusive); **`shared_preferences` não é cofre** —
   credencial em `flutter_secure_storage`/Keychain/Keystore.
9. **`pubspec.lock` commitado em aplicação**; SDK e versão do Flutter **fixados** no CI.
10. **Os lints do piso ficam explícitos** no `analysis_options.yaml` — herdar `flutter_lints` **não
    basta**, e é o `flutter analyze` que trava o merge.
11. **Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige → re-decompõe → só então `opus`, com motivo). **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata. Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.

## Relação com as outras skills

- **`schematize-mobile`** — o piso de app; **ela manda** no que é de produto/plataforma, inclusive
  na decisão *nativo vs cross*.
- **`schematize-engineering`** — a base e o rol. **Backend em Dart não é do rol**; web
  institucional/marketing é da **`schematize-web`**, não Flutter Web.
- **`schematize-qa`** — a disciplina de teste; aqui muda o runner e as armadilhas
  (`pumpAndSettle`, golden test que quebra por plataforma).
- **`schematize-swift`/`schematize-kotlin`** — as respostas **nativas** da mesma pergunta; o plugin
  com código nativo cai no piso delas.
