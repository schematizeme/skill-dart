#!/usr/bin/env bash
# Vermelho primeiro do gate de Dart.
#
# strict-ok: harness de teste — continua depois de um caso vermelho (`schematize-shell` -> `references/piso.md` secao 1)
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-dart.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM
ok=0; fail=0
caso() {
  local nome="$1" esp="$2" agulha="$3" arq="${4:-alvo.dart}"
  local d="$TMP/$nome"; mkdir -p "$d"; cat > "$d/$arq"
  local saida; saida="$(bash "$G" "$d" 2>&1)"; local rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $nome: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $nome: exit certo, saída sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $nome"; ok=$((ok+1))
}

echo "== verde de partida =="
caso verde 0 "regras textuais do piso" <<'FIX'
import 'dart:async';

sealed class Estado {}

class Carregando extends Estado {}

class Pronto extends Estado {
  Pronto(this.itens);
  final List<String> itens;
}

class Repositorio {
  StreamSubscription<String>? _sub;

  void ouvir(Stream<String> fonte, void Function(String) aoReceber) {
    _sub = fonte.listen(aoReceber);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
FIX

echo "== null safety =="
caso bang 1 "null safety pela qual você pagou" <<'FIX'
String nome(Map<String, String> m) {
  return m['nome']!;
}
FIX

echo "== assíncrono e vazamento =="
caso listen-sem-cancel 1 "não cancelada é vazamento" <<'FIX'
import 'dart:async';

void ouvir(Stream<String> fonte) {
  fonte.listen((v) => sink.add(v));
}
FIX

echo "== erro engolido =="
caso catch-vazio 1 "erro engolido" <<'FIX'
Future<void> salvar() async {
  try {
    await gravar();
  } catch (e) {}
}
FIX

echo "== segurança do cliente =="
caso prefs-com-token 1 "plist/XML EM CLARO" <<'FIX'
import 'package:shared_preferences/shared_preferences.dart';

Future<void> guardar(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}
FIX

echo "== projeto: lock e lints =="
d="$TMP/sem-lock"; mkdir -p "$d"
printf 'void main() {}\n' > "$d/main.dart"
printf 'name: app\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$d/pubspec.yaml"
printf 'linter:\n  rules:\n    - unawaited_futures\n' > "$d/analysis_options.yaml"
saida="$(bash "$G" "$d" 2>&1)"; rc=$?
if [ "$rc" = 1 ] && grep -qF "pubspec.lock ausente" <<<"$saida"; then echo "  ✔ aplicação sem pubspec.lock reprova"; ok=$((ok+1))
else echo "  ✖ sem lock: exit $rc"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); fi

d="$TMP/sem-analysis"; mkdir -p "$d"
printf 'void main() {}\n' > "$d/main.dart"
printf 'name: app\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n' > "$d/pubspec.yaml"; : > "$d/pubspec.lock"
saida="$(bash "$G" "$d" 2>&1)"; rc=$?
if [ "$rc" = 1 ] && grep -qF "analysis_options.yaml" <<<"$saida"; then echo "  ✔ projeto sem analysis_options reprova"; ok=$((ok+1))
else echo "  ✖ sem analysis_options: exit $rc"; fail=$((fail+1)); fi

echo "== teste pode usar bang =="
caso bang-em-teste 0 "" "repositorio_test.dart" <<'FIX'
import 'package:test/test.dart';

void main() {
  test('acha', () {
    final m = {'a': 1};
    expect(m['a']!, 1);
  });
}
FIX

echo "== nada para verificar =="
d="$TMP/vazio"; mkdir -p "$d"; echo "# prosa" > "$d/LEIA.md"
saida="$(bash "$G" "$d" 2>&1)"; rc=$?
if [ "$rc" = 2 ] && grep -q "não é aprovação" <<<"$saida"; then echo "  ✔ repo sem .dart sai 2 (não 0)"; ok=$((ok+1))
else echo "  ✖ repo sem .dart: exit $rc"; fail=$((fail+1)); fi

echo; echo "check-dart: $ok ok, $fail falha(s)"; [ "$fail" = 0 ]
