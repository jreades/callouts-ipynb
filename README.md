# callouts-ipynb

A Quarto filter that rewrites callouts as Jupyter-style alert boxes when rendering to `ipynb`.
Quarto's own callouts show up as plain blockquotes in notebooks; this maps them to the
`alert alert-block alert-*` classes that Jupyter understands, with an icon before the title.
Other output formats (HTML, PDF, RevealJS, ...) are left untouched.

## Installing

```bash
quarto add <user>/callouts-ipynb
```

This installs the extension into `_extensions/` in the current project.

## Using

Add the filter to a document's front matter:

```yaml
filters:
  - callouts-ipynb
```

or to `_quarto.yml` to apply it project-wide:

```yaml
filters:
  - callouts-ipynb
```

## Mapping

| Quarto callout | Jupyter class   | Icon |
|----------------|-----------------|------|
| `note`         | `alert-info`    | &#128221; |
| `tip`          | `alert-success` | &#128161; |
| `warning`      | `alert-warning` | &#9888;&#65039; |
| `caution`      | `alert-warning` | &#128679; |
| `important`    | `alert-danger`  | &#10071; |

Jupyter has no `alert-caution` class, so `caution` shares `alert-warning` with `warning`.
To change classes or icons, edit the `map` table at the top of
`_extensions/callouts-ipynb/callouts-ipynb.lua`.

## Supported callout options

- **Title:** from the `title=` attribute or a leading `## Heading`; defaults to the type name.
- **`icon=false`:** omits the icon.
- **`collapse=true|false`:** rendered as `<details>` inside the alert (`open` when `false`).

## Limitations

The callout body is rendered to markdown with `pandoc.write` so that the whole callout stays
inside one markdown cell. Executable code chunks or other Quarto custom nodes nested inside a
callout may not survive this.

## Example

`example.qmd` exercises every callout type; `example.ipynb` is its rendered output.
To regenerate: `quarto render example.qmd --to ipynb`.
