# Shared Sofia root resolution.
# Tooling scripts live in the public sofia checkout; private writing envs set SOFIA_ROOT.
# Usage: source this file after defining nothing critical; sets SOFIA_ROOT and TOOLING_ROOT.

_sofia_tooling_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOOLING_ROOT="${TOOLING_ROOT:-$_sofia_tooling_root}"

if [ -n "${SOFIA_ROOT:-}" ]; then
  :
elif [ -d "$PWD/corpus/works" ] || [ -d "$PWD/corpus/incoming" ]; then
  SOFIA_ROOT="$PWD"
else
  SOFIA_ROOT="$TOOLING_ROOT"
fi

export SOFIA_ROOT TOOLING_ROOT
