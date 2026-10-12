# Third-party components

This project vendors Hugo PaperMod from https://github.com/adityatelange/hugo-PaperMod.

- Revision: `d3768854d00ad003b0a8dbdba254ce9224377a01`
- Obtained from the official GitHub source archive on 2026-10-12.
- License: MIT; full license preserved at `themes/PaperMod/LICENSE`.
- PaperMod bundles Fuse.js and theme assets with their upstream notices intact.
- Root-level overrides of `baseof.html`, `rss.xml`, and `templates/opengraph.html` retain the upstream templates with Hugo 0.167 locale/direction compatibility changes.

Hugo is downloaded separately from its official release and checked against the release SHA-256 checksum. It is not included in the source repository.

The optional comment integration loads https://giscus.app/client.js after real repository/category identifiers have been configured. See https://github.com/giscus/giscus for its license and source.
