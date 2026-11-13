# Standard docs recipes: the spec viewer and design-docs rendering — imported by every project's justfile:
#
#     export DOCS_SRC := "docs/design"     # optional; this is the default
#     import '.standards/just/docs.just'
#
# Renders <DOCS_SRC>/*.md → styled HTML + PDF and <DOCS_SRC>/*.svg → a
# standalone full-size PDF each, into <DOCS_OUT> (default publish/, gitignored).
# See PROJECT_STANDARDS.md > Design docs & diagrams.

# Render design docs (md + svg) → publish/ as HTML + PDF (pandoc, librsvg, Chrome)
[no-exit-message]
[group('docs')]
docs-pdf:
    ./bin/build-docs

# Render the design docs, then open the output directory
[group('docs')]
docs-open: docs-pdf
    open "${DOCS_OUT:-publish}/"

# Browse spec/ in the docs viewer: any branch, and its proposed changes vs main
[group('docs')]
spec port="4800":
    ./bin/spec-viewer --port {{port}} --open
