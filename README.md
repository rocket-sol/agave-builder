# agave-builder

Automated agave solana validator builds.

## Usage

Build a generic x86_64 build.

    make build

This produces a `build` directory containing the agave build.

Create release assets for GitHub.

    make release

Publish the release to GitHub (manually). Normally the release is created automatically after a new AGAVE_VERSION is merged to `main`.

    make publish

Sign the release assets and upload to the existing release.

    make publish
