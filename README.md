# Python Semantic Release Composite Action
Composite action for PSR.
Official project is here:
  https://github.com/python-semantic-release/python-semantic-release

This action use PSR in the worker environment directly.
Python must be installed.

You may use a specific version of PSR with this action.
For now, only versions 8 and 9 are supported.

## Options

| Name                      | Type | Description|
|---------------------------|------------|------------|
|`root_options`             | string | Additional options for the main command. Example: -vv --noop|
|`directory`                | string | Sub-directory to cd into before running semantic-release|
|`github_token`             | string | GitHub token used to push release notes and new commits/tags|
|`git_committer_name`       | string | The human name for the “committer” field|
|`git_committer_email`      | string | The email address for the “committer” field|
|`ssh_public_signing_key`   | string | The ssh public key used to sign commits|
|`ssh_private_signing_key`  | string | The ssh private key used to sign commits|
|`prerelease`               | boolean | Force the next version to be a prerelease. Set to "true" or "false".|
|`prerelease_token`         | string | Force the next version to use this prerelease token, if it is a prerelease.|
|`force`                    | string | Force the next version to be a major release. Must be set to one of "prerelease", "patch", "minor", or "major". |
|`commit`                   | boolean | Whether or not to commit changes locally. Defaults are handled by python-semantic-release internal version command. |
|`tag`                      | boolean | Whether or not to make a local version tag. Defaults are handled by python-semantic-release internal version command.|
|`push`                     | boolean | Whether or not to push local commits to the Git repository. See the configuration page for defaults of `semantic-release version` for how the default is determined between push, tag, & commit.|
|`changelog`                | boolean | Whether or not to update the changelog.|
|`vcs_release`              | boolean | Whether or not to create a release in the remote VCS, if supported|
|`build`                    | boolean | Whether or not to run the build_command for the project. Defaults are handled by python-semantic-release internal version command.|
|`build_metadata`           | string | Build metadata to append to the new version|
|`psr_version`              | string | Pin python-semantic-release version to a specific value|

### Example of use

```yaml
jobs:
  psr:
    # Python is installed by default on github workers
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: ./action
        with:
          github_token: ${{ secrets.PAT_TOKEN }}
          root_options: -v
          prerelease: true
          commit: true
          push: true
          vcs_release: false
          psr_version: 8.7.0
```
