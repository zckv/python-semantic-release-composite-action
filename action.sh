bool() {
    input="$1"
    option1="$2"
    option2="$3"
    if [ -z "$input" ]; then
    echo ""
    elif [ "$input" = "true" ]; then
    echo "$option1"
    elif [ "$input" = "false" ]; then
    echo "$option2"
    else
    echo "$option1"
    fi
}
set -eux
export ARGS=""
case $(echo "$INPUT_PSR_VERSION" | cut -d '.' -f1) in
"9")
    ARGS+="$(bool "$INPUT_PRERELEASE" "--as-prerelease " "")"
    ARGS+="$(bool "$INPUT_COMMIT" "--commit " "--no-commit ")"
    ARGS+="$(bool "$INPUT_TAG" "--tag " "--no-tag ")"
    ARGS+="$(bool "$INPUT_PUSH" "--push " "--no-push ")"
    ARGS+="$(bool "$INPUT_CHANGELOG" "--changelog " "--no-changelog ")"
    ARGS+="$(bool "$INPUT_VCS_RELEASE" "--vcs-release " "--no-vcs-release ")"
    ARGS+="$(bool "$INPUT_BUILD" "" "--skip-build ")"
    force_levels=("prerelease" "patch" "minor" "major")
    if [ -z "$INPUT_FORCE" ]; then
    true # do nothing if 'force' input is not set
    elif
    echo '%s\0' "${force_levels[@]}" | grep -Fxzq "$INPUT_FORCE"
    then
    ARGS+="--$INPUT_FORCE "
    else
    echo "Error: Input 'force' must be one of: %s" >&2
    echo "${force_levels[@]}" >&2
    fi

    if [ -n "$INPUT_BUILD_METADATA" ]; then
        ARGS+="--build-metadata $INPUT_BUILD_METADATA "
    fi

    if [ -n "$INPUT_PRERELEASE_TOKEN" ]; then
        ARGS+=("--prerelease-token $INPUT_PRERELEASE_TOKEN")
    fi
    ;;
"8")
    ARGS+="$(bool "$INPUT_PRERELEASE" "--as-prerelease " "")"
    ARGS+="$(bool "$INPUT_COMMIT" "--commit " "--no-commit ")"
    ARGS+="$(bool "$INPUT_PUSH" "--push " "--no-push ")"
    ARGS+="$(bool "$INPUT_CHANGELOG" "--changelog " "--no-changelog ")"
    ARGS+="$(bool "$INPUT_VCS_RELEASE" "--vcs-release " "--no-vcs-release ")"
    force_levels=("patch" "minor" "major")
    if [ -z "$INPUT_FORCE" ]; then
    true # do nothing if 'force' input is not set
    elif
    echo '%s\0' "${force_levels[@]}" | grep -Fxzq "$INPUT_FORCE"
    then
    args+="--$input_force "
    else
    echo "Error: Input 'force' must be one of: %s" >&2
    echo "${force_levels[@]}" >&2
    fi

    if [ -n "$INPUT_BUILD_METADATA" ]; then
        ARGS+="--build-metadata $INPUT_BUILD_METADATA "
    fi
    ;;
esac


# Change to configured directory
cd "${INPUT_DIRECTORY}"

# Set Git details
if ! [ "${INPUT_GIT_COMMITTER_NAME:="-"}" = "-" ]; then
    git config user.name "$INPUT_GIT_COMMITTER_NAME"
fi
if ! [ "${INPUT_GIT_COMMITTER_EMAIL:="-"}" = "-" ]; then
    git config user.email "$INPUT_GIT_COMMITTER_EMAIL"
fi
if (
    [ "${INPUT_GIT_COMMITTER_NAME:="-"}" != "-" ] &&
    [ "${INPUT_GIT_COMMITTER_EMAIL:="-"}" != "-" ]
    );
then
    # Must export this value to the environment for PSR to consume the override
    export GIT_COMMIT_AUTHOR="$INPUT_GIT_COMMITTER_NAME <$INPUT_GIT_COMMITTER_EMAIL>"
fi

# See https://github.com/actions/runner-images/issues/6775#issuecomment-1409268124
# and https://github.com/actions/runner-images/issues/6775#issuecomment-1410270956
# git config --system --add safe.directory "*"

if (
    [[ -n "$INPUT_SSH_PUBLIC_SIGNING_KEY" &&
    -n "$INPUT_SSH_PRIVATE_SIGNING_KEY" ]]
);
then
    echo "SSH Key pair found, configuring signing..."

    # Write keys to disk
    mkdir -vp ~/.ssh
    echo -e "$INPUT_SSH_PUBLIC_SIGNING_KEY" >>~/.ssh/signing_key.pub
    cat ~/.ssh/signing_key.pub
    echo -e "$INPUT_SSH_PRIVATE_SIGNING_KEY" >>~/.ssh/signing_key
    # DO NOT CAT private key for security reasons
    sha256sum ~/.ssh/signing_key
    # Ensure read only private key
    chmod 400 ~/.ssh/signing_key

    # Enable ssh-agent & add signing key
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/signing_key

    # Create allowed_signers file for git
    if [ "${INPUT_GIT_COMMITTER_EMAIL:="-"}" = "-" ]; then
            echo >&2 "git_committer_email must be set to use SSH key signing!"
            exit 1
    fi
    touch ~/.ssh/allowed_signers
    echo "$INPUT_GIT_COMMITTER_EMAIL $INPUT_SSH_PUBLIC_SIGNING_KEY" >~/.ssh/allowed_signers

    # Configure git for signing
    git config gpg.format ssh
    git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
    git config user.signingKey ~/.ssh/signing_key
    git config commit.gpgsign true
    git config tag.gpgsign true
fi

# Copy inputs into correctly-named environment variables
export GH_TOKEN="${INPUT_GITHUB_TOKEN}"

source ~/semantic-release/.venv/bin/activate
semantic-release $INPUT_ROOT_OPTIONS version $ARGS
