#!/usr/bin/env bash
# schematize-dart — o gate. Cobra o piso de `references/piso.md` sobre o Dart do repo.
#
# HONESTIDADE SOBRE O ALCANCE: este gate é TEXTUAL — ele não compila. Onde existir `flutter analyze`
# (com o `analysis_options.yaml` do projeto), é ELE que manda, e o gate diz isso na saída.
#
# strict-ok: COLETOR — varre tudo e soma os achados (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail

raiz="${1:-.}"
erros=(); avisos=()

arquivos=()
while IFS= read -r -d '' f; do arquivos+=("$f"); done < <(
  find "$raiz" -type f -name '*.dart' \
    -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/.git/*' \
    -not -path '*/versions/*' -not -name '*.g.dart' -not -name '*.freezed.dart' -print0 2>/dev/null
)
if [ "${#arquivos[@]}" -eq 0 ]; then
  echo "✖ nenhum .dart em $raiz — nada para verificar (ausência de material não é aprovação)." >&2
  exit 2
fi

command -v flutter >/dev/null 2>&1 || command -v dart >/dev/null 2>&1 \
  || avisos+=("SDK do Dart/Flutter ausente nesta máquina: o gate rodou só as regras TEXTUAIS. Onde houver \`flutter analyze\`, é ele que manda")

# --------------------------------------------------------- projeto: lock e lints exigidos
if [ -f "$raiz/pubspec.yaml" ]; then
  ehApp=0
  grep -qE '^\s*flutter:\s*$|^\s*sdk:\s*flutter' "$raiz/pubspec.yaml" && ehApp=1
  if [ "$ehApp" = 1 ] && [ ! -f "$raiz/pubspec.lock" ]; then
    erros+=("pubspec.lock ausente numa APLICAÇÃO — sem lock, duas máquinas resolvem versões diferentes (plataforma.md secao 1)")
  fi
  grep -qE '^\s*environment:' "$raiz/pubspec.yaml" \
    || erros+=("pubspec.yaml sem \`environment: sdk:\` — a versão do SDK é declarada, não herdada")
  grep -qE '^\s*dependency_overrides:' "$raiz/pubspec.yaml" \
    && avisos+=("\`dependency_overrides\` presente — é dívida com data: registre por que existe e quando sai")
fi
if [ -f "$raiz/analysis_options.yaml" ]; then
  for lint in unawaited_futures use_build_context_synchronously avoid_dynamic_calls cancel_subscriptions; do
    grep -qE "^\s*-?\s*$lint\s*:?\s*(true)?\s*$" "$raiz/analysis_options.yaml" \
      || avisos+=("analysis_options.yaml sem \`$lint\` explícito — herdar flutter_lints NÃO basta (stack-versoes.md)")
  done
else
  [ -f "$raiz/pubspec.yaml" ] && erros+=("sem \`analysis_options.yaml\` — o gate do projeto é o \`flutter analyze\`, e ele precisa das regras do piso ligadas")
fi

# --------------------------------------------------------- piso por arquivo
for f in "${arquivos[@]}"; do
  nome="${f#"$raiz"/}"
  ehTeste=0; case "$nome" in *_test.dart|*/test/*|*/integration_test/*) ehTeste=1 ;; esac
  # ordem: string primeiro, comentário depois
  codigo="$(sed -e "s/'[^']*'/''/g" -e 's/"[^"]*"/""/g' -e 's|//.*$||' "$f")"

  if [ "$ehTeste" = 0 ]; then
    grep -qE '[]A-Za-z_)]![]. ),;]|[]A-Za-z_)]!$' <<< "$codigo" \
      && erros+=("$nome: usa \`!\` (bang) — desliga exatamente a verificação de null safety pela qual você pagou a migração")
    grep -qE '\blate\s+(final\s+)?[A-Z]' <<< "$codigo" \
      && avisos+=("$nome: \`late\` — só onde o ciclo de vida garante inicialização; \`LateInitializationError\` não diz mais que um null")
  fi
  grep -qE '\bdynamic\b' <<< "$codigo" \
    && avisos+=("$nome: \`dynamic\` — desliga a checagem em compilação e vira NoSuchMethodError em produção")
  grep -qE 'catch\s*\([^)]*\)\s*\{\s*\}' <<< "$codigo" \
    && erros+=("$nome: \`catch\` vazio — erro engolido")
  grep -qE 'catch\s*\(\s*[a-z]+\s*\)\s*\{\s*print\(' <<< "$codigo" \
    && avisos+=("$nome: \`catch (e) { print(e); }\` — print não é log de produção e o stack trace some (use \`on X catch (e, s)\`)")
  grep -qE '\bprint\s*\(' <<< "$codigo" && [ "$ehTeste" = 0 ] \
    && avisos+=("$nome: \`print\` — sem nível, sem contexto, some no release; use o logger do projeto")
  # BuildContext depois de await, sem checar mounted
  if grep -qE 'await ' <<< "$codigo" && grep -qE '\bcontext\b' <<< "$codigo" && ! grep -qE 'mounted' "$f"; then
    avisos+=("$nome: usa \`context\` num arquivo com \`await\` e sem \`mounted\` — o widget pode ter sido desmontado (a armadilha nº 1 do Flutter)")
  fi
  # stream sem cancel
  if grep -qE '\.listen\(' <<< "$codigo" && ! grep -qE 'cancel\(\)' "$f"; then
    erros+=("$nome: \`.listen(\` sem \`cancel()\` no arquivo — subscription não cancelada é vazamento e dispara setState depois da tela morrer")
  fi
  grep -qE 'shared_preferences|SharedPreferences' <<< "$codigo" \
    && grep -qiE 'token|senha|password|secret' "$f" \
    && erros+=("$nome: credencial em \`shared_preferences\` — é plist/XML EM CLARO; use flutter_secure_storage")
  grep -qE 'javascriptMode:\s*JavascriptMode\.unrestricted|\.setJavaScriptMode\(\s*JavaScriptMode\.unrestricted' <<< "$codigo" \
    && avisos+=("$nome: WebView com JS irrestrito — só com conteúdo próprio; o canal JS↔Dart é ponte de execução")
done

for a in "${avisos[@]:-}"; do [ -n "$a" ] && echo "  ! $a" >&2; done
if [ "${#erros[@]}" -gt 0 ]; then
  echo "" >&2
  echo "✖ DART REPROVADO — ${#erros[@]} problema(s) em ${#arquivos[@]} arquivo(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  exit 1
fi
echo "✔ dart: ${#arquivos[@]} arquivo(s) nas regras textuais do piso."
