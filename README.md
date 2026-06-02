# germade-actions

Reusable GitHub composite actions for CI/CD and release workflows.

## Available Actions

| Action | Path | Purpose |
| --- | --- | --- |
| Artifact | `artifact` | Save/load files or folders as workflow artifacts, with optional compression. |
| Upload to S3 | `upload-to-s3` | Sync build outputs to Amazon S3 with cache-control options. |
| GitHub Deploy | `github-deployment` | Create and update GitHub Deployments and deployment statuses. |
| GitHub Release | `github-release` | Create GitHub releases, upload assets, and optionally return changelog text. |
| Setup AWS CLI | `setup-aws-cli` | Ensure AWS CLI is installed and configure AWS credentials via OIDC. |
| Export Story details | `story-details` | Extract story ID, PR number, and branch metadata from GitHub context. |
| Install Missing Commands | `system-setup` | Optionally set up Node and install missing Linux commands on runner. |

## Quick Start

Use these actions from another workflow in the same repository:

```yaml
jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Export story details
        uses: ./story-details
```

From a different repository, reference this repo and a ref (tag/branch/SHA):

```yaml
- uses: <owner>/germade-actions/story-details@<ref>
```

## Action Reference

### 1) Artifact (`artifact`)

Save or load artifacts, optionally compressing directories as `.tar.gz`.

Inputs:
- `path` (required): Source path to save, or destination path to load into.
- `name` (optional, default: `""`): Artifact name. If omitted, defaults to `path-<path>`.
- `compressed` (optional, default: `false`): `true` to compress/decompress directories.
- `action` (required): `save`/`upload` or `load`/`download`.

Outputs:
- None declared.

Example:

```yaml
- name: Save dist as compressed artifact
  uses: ./artifact
  with:
    action: save
    path: dist
    name: web-dist
    compressed: true

- name: Load dist artifact
  uses: ./artifact
  with:
    action: load
    path: dist
    name: web-dist
    compressed: true
```

### 2) Upload to S3 (`upload-to-s3`)

Deploy local files to S3 using `aws s3 sync`, with optional no-cache override for matched files.

Inputs:
- `profile` (required): AWS CLI profile name.
- `bucket-target` (required): Destination bucket.
- `source-path` (required): Local path to deploy.
- `bucket-path` (optional, default: `""`): S3 prefix/folder.
- `acl` (optional, default: `private`): Canned ACL, for example `public-read`.
- `no-cache` (optional, default: `false`): Pattern to upload with `no-cache, no-store`.

Outputs:
- None declared.

Example:

```yaml
- name: Deploy web app
  uses: ./upload-to-s3
  with:
    profile: default
    bucket-target: my-bucket
    source-path: ./dist
    bucket-path: web/app
    acl: public-read
    no-cache: "*.html"
```

### 3) GitHub Deploy (`github-deployment`)

Create a GitHub Deployment and optionally update it as `success` and/or `inactive`.

Inputs:
- `github-token` (optional, default: `github.token`): Token with deployment permissions.
- `github-api-version` (optional, default: `2026-03-10`): API version header value.
- `create` (optional, default: `false`): Whether to create a deployment.
- `deployment-id` (optional, default: `""`): Existing deployment ID to reuse.
- `success` (optional, default: `false`): Mark deployment state as success.
- `close` (optional, default: `false`): Mark deployment state as inactive.
- `environment` (required): Deployment environment name.
- `target-url` (optional, default: `""`): URL for deployed environment.
- `ref` (optional, default: `github.ref`): Git ref to deploy.
- `auto-merge` (optional, default: `false`): Auto-merge behavior for deployment.

Outputs:
- `deployment_id`: Created or reused deployment ID.

Example:

```yaml
- name: Create deployment
  id: gh_deploy
  uses: ./github-deployment
  with:
    create: true
    environment: preview
    target-url: https://preview.example.com

- name: Mark deployment as successful
  uses: ./github-deployment
  with:
    deployment-id: ${{ steps.gh_deploy.outputs.deployment_id }}
    environment: preview
    success: true
```

### 4) GitHub Release (`github-release`)

Create a release if missing, upload optional attachments, and optionally output changelog text.

Inputs:
- `github-token` (optional, default: `github.token`): Token with release permissions.
- `github-api-version` (optional, default: `2026-03-10`): API version header value.
- `tag` (required): Release tag.
- `target-commitish` (optional, default: `github.ref_name`): Branch/tag/SHA target.
- `attachments` (optional): Multiline list. Each line:
  - `path/to/file`
  - `path/to/file -> custom-name.ext`
- `changelog` (optional): Release notes body.
- `get_changelog` (optional, default: `false`): Generate/return release body as output.

Outputs:
- `release-id`: Release ID.
- `release-json`: Full release payload.
- `changelog`: Release body when requested.

Example:

```yaml
- name: Create release
  id: release
  uses: ./github-release
  with:
    tag: v1.2.0
    get_changelog: true
    attachments: |
      dist/app.zip
      dist/checksums.txt -> SHA256SUMS.txt
```

### 5) Setup AWS CLI (`setup-aws-cli`)

Install AWS CLI on Linux runners (if missing) and configure credentials via OIDC role assumption.

Inputs:
- `aws_oidc_role` (required): IAM role ARN to assume.
- `aws_region` (required): AWS region.

Outputs:
- None declared.

Example:

```yaml
- name: Configure AWS
  uses: ./setup-aws-cli
  with:
    aws_oidc_role: arn:aws:iam::123456789012:role/gha-oidc-role
    aws_region: eu-west-1
```

### 6) Export Story details (`story-details`)

Extract useful branch/PR metadata for ephemeral environments.

Outputs:
- `story-id`: First matched story token like `abc-123` from branch/PR ref.
- `pr`: Pull request number (if available).
- `branch`: Resolved branch name.
- `ephemeral-folder`: `story-id`, else `pr-<num>`, else `unknown`.

Inputs:
- None.

Example:

```yaml
- name: Export story details
  id: story
  uses: ./story-details

- name: Print ephemeral folder
  run: echo "${{ steps.story.outputs.ephemeral-folder }}"
```

### 7) Install Missing Commands (`system-setup`)

Optional environment preparation for Linux runners.

Inputs:
- `checkout` (optional, default: `false`): Run checkout first.
- `node-setup` (optional, default: `false`): Run setup-node.
- `node-version` (optional, default: `""`): Node version string.
- `node-version-file` (optional, default: `""`): Version file path, for example `.nvmrc`.
- `install-node-dependencies` (optional, default: `false`): Run `npm install`.
- `install-node-dependencies-no-save` (optional, default: `false`): Run `npm install --no-save`.
- `install-linux-commands` (optional, default: `""`): Space-separated commands/packages to install when missing.

Outputs:
- None declared.

Example:

```yaml
- name: Prepare CI environment
  uses: ./system-setup
  with:
    checkout: true
    node-setup: true
    node-version-file: .nvmrc
    install-node-dependencies: true
    install-linux-commands: jq yq
```

## Notes

- Most actions assume Linux runners (`bash` and `apt-get` usage in some actions).
- For AWS and release/deployment actions, ensure workflow permissions and tokens are configured.
- For cross-repo usage, prefer version tags over branches.
