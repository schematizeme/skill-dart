# Piso de Dart/Flutter (schematize-dart) — sempre-on

> No que é de **app** (offline, IAM, push, loja, teste no device), quem manda é a
> **`schematize-mobile`**. Aqui é o que é de **linguagem e framework**.

1. **`!` (bang) é VETADO** em produção — desliga a verificação pela qual você pagou a migração.
2. **`late` não conserta nulo incômodo**; **`dynamic`** vira `NoSuchMethodError` em produção.
3. **Todo `Future` é aguardado** ou `unawaited(...)` explícito, com motivo.
4. **Stream tem `cancel()` no `dispose()`** (idem `Timer`, `AnimationController`) — senão vaza e
   dispara `setState` depois da tela morrer.
5. **`BuildContext` depois de `await` exige `if (!mounted) return;`**.
6. **CPU pesado fora da UI thread** (`compute`/`Isolate`) — o sintoma de ignorar é jank.
7. **`const` onde der**; **`Key`** em lista dinâmica; nada de lógica de negócio no `build`.
8. **Erro com stack trace** (`on X catch (e, s)`); `catch (e) {}` e `print` como tratamento são
   VETADOS.
9. **Segredo nunca no bundle** (nem via `--dart-define`); **`shared_preferences` não é cofre**.
10. **`pubspec.lock` commitado** (aplicação), SDK fixado, e os **lints do piso explícitos** no
    `analysis_options.yaml` — herdar `flutter_lints` não basta.
11. **Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e
    revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige →
    re-decompõe → só então `opus`, com motivo). **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata. Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.

Gate: `bash .claude/skills/schematize-dart/scripts/check-dart.sh .`
