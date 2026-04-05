# apfeller-apps

`apfeller-apps` is the source-of-truth repo for published `apfeller` apps.

It contains:

- author-facing app definitions under `apps/<id>/app.toml`
- shared shell packaging that compiles app bundles plus `catalog/latest.tsv`
- CI that validates schema and packaging
- a publish workflow that uploads per-app bundle releases and refreshes the raw catalog consumed by `apfeller`

`apfeller` reads the catalog from:

```text
https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv
```

## Local packaging

```sh
scripts/package_catalog.sh --output-dir dist
```

That produces:

- `dist/apfeller-catalog.tsv`
- `dist/<app>-<revision>.tar.gz`

Each bundle revision is generated from `app.toml` plus any declared hook files.

## Publish model

- Each app bundle is published to a GitHub release tagged `<app>-<revision>`
- `catalog/latest.tsv` is committed on `main`
- `apfeller` installs apps from the exact `bundle_url` values listed in that catalog
