SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPTS_DIR/../settings.sh"

# Overridden by the ../settings.sh file
LOCAL_ADMIN_USER=${LOCAL_ADMIN_USER:-root}
LOCAL_ADMIN_PASSWORD=${LOCAL_ADMIN_PASSWORD:-password}
REMOTE_DCS_URL=${REMOTE_DCS_URL:-https://git.door43.org}

API_URL="${REMOTE_DCS_URL}/api/v1"
# This port does not need to be changed as this is accessed within the docker container
LOCALHOST="http://${LOCAL_ADMIN_USER}:${LOCAL_ADMIN_PASSWORD}@localhost:3000"

GITEA="${GITEA:-/app/gitea/gitea}"
TMPDIR="${TMPDIR:-/tmp}"

OWNERS_FILE="${OWNERS_FILE:-$SCRIPTS_DIR/../source_owners.txt}"
SUBJECTS_FILE="${SUBJECTS_FILE:-$SCRIPTS_DIR/../source_subjects.txt}"
LANGUAGES_FILE="${LANGUGES_FILE:-$SCRIPTS_DIR/../source_languages.txt}"
TYPES_FILE="${TYPES_FILE:-$SCRIPTS_DIR/../source_metadata_types.txt}"
ORG_FILE="${ORG_FILE:-$SCRIPTS_DIR/../target_org.txt}"
SOURCE_CATALOG_FILE="${SOURCE_CATALOG_FILE:-$TMPDIR/source_catalog.json}"
TARGET_CATALOG_FILE="${TARGET_CATALOG_FILE:-$TMPDIR/target_catalog.json}"
