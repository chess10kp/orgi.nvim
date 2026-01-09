; Tree-sitter grammar for Org mode
; Focused on orgi's use case

module_name = "org"

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "*"
  "+"
  ":"
  "="
  "\""
  "\\"
  "'"
] @punctuation.delimiter

"=" @operator

[
  "TODO"
  "INPROGRESS"
  "DONE"
  "KILL"
] @keyword

[
  "#A"
  "#B"
  "#C"
] @constant

:PROPERTIES: @keyword
:END: @keyword
:ID: @keyword
:TITLE: @keyword
:CREATED: @keyword

:tag: @label

(headline
  (stars
    (star) @punctuation.special)
  (keyword) @keyword
  (priority) @constant
  (title) @string)

(stars
  (star) @punctuation.special) @repeat

(priority) @constant

(title) @string

(body) @comment

(properties
  (property
    (keyword) @keyword
    (value) @string))

(tag) @label

(list
  (item) @variable)
