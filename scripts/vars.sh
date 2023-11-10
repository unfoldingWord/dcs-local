SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ROOT_USER="root"
ROOT_PASSWORD="asecurepassword"

DCS_HOST="${DCS_HOST:-https://git.door43.org}"
API_URL="${DCS_HOST}/api/v1"
LOCALHOST="http://$ROOT_USER:$ROOT_PASSWORD@localhost:3000"
# NOTE: READ_ONLY_PUBLIC_REPO_AUTH_TOKEN is a token for the dcs-local user on prod DCS to be able to READ PUBLIC repos only!
#       It is required for migration of a repo from a remote instance of Gitea and to be able to get its releases, which are
#       needed for our apps to know what version of the source to get.
READ_ONLY_PUBLIC_REPO_AUTH_TOKEN="d54df420a8d39f9cec8394a73c6b44a2afcd0916"

GITEA="${GITEA:-/app/gitea/gitea}"
TMPDIR="${TMPDIR:-/tmp}"

OWNERS_FILE="${OWNERS_FILE:-$SCRIPTS_DIR/../source_owners.txt}"
SUBJECTS_FILE="${SUBJECTS_FILE:-$SCRIPTS_DIR/../source_subjects.txt}"
LANGUAGES_FILE="${LANGUGES_FILE:-$SCRIPTS_DIR/../source_languages.txt}"
TYPES_FILE="${TYPES_FILE:-$SCRIPTS_DIR/../source_metadata_types.txt}"