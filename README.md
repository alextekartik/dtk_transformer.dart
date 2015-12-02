# dtk_transformer.dart

Transformer to assemble html

[![Build Status](https://travis-ci.org/alextekartik/dtk_transformer.dart.svg?branch=master)](https://travis-ci.org/alextekartik/dtk_transformer.dart)

## Html transformation

* Any html file
* ignore files starting with `'_'`, ending with `'.part.html'`

i.e.

Valid
* `index.html`

Invalid (ignored and consumed)
* `_index.html`
* `index.part.html`

### Include


    <meta property="dtk-include" content="part/included.html">

