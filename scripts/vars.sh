SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ROOT_USER="root"
ROOT_PASSWORD="asecurepassword"

DCS_HOST="${DCS_HOST:-https://git.door43.org}"
API_URL="${DCS_HOST}/api/v1"
LOCALHOST="http://$ROOT_USER:$ROOT_PASSWORD@localhost:3000"

GITEA="${GITEA:-/app/gitea/gitea}"
TMPDIR="${TMPDIR:-/tmp}"

OWNERS_FILE="${OWNERS_FILE:-$SCRIPTS_DIR/../source_owners.txt}"
SUBJECTS_FILE="${SUBJECTS_FILE:-$SCRIPTS_DIR/../source_subjects.txt}"
LANGUAGES_FILE="${LANGUGES_FILE:-$SCRIPTS_DIR/../source_languages.txt}"
TYPES_FILE="${TYPES_FILE:-$SCRIPTS_DIR/../source_metadata_types.txt}"