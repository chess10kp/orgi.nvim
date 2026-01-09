module.exports = grammar({
  name: 'org',

  extras: $ => [
    /\s/,
    $.comment,
  ],

  rules: {
    document: $ => repeat($._node),

    _node: $ => choice(
      $.headline,
      $.comment,
    ),

    headline: $ => seq(
      $.stars,
      optional($.priority),
      field('keyword', choice('TODO', 'INPROGRESS', 'DONE', 'KILL')),
      field('title', $.title),
      optional($.tags),
      optional($._content),
    ),

    stars: $ => token(repeat1('*')),

    priority: $ => token(seq('[', choice('#A', '#B', '#C'), ']')),

    title: $ => /.+/,

    tags: $ => token(seq(':', repeat1(/[^:]+/), ':')),

    _content: $ => choice(
      $.properties,
      $.body,
    ),

    properties: $ => seq(
      ':PROPERTIES:',
      repeat($.property),
      ':END:',
    ),

    property: $ => seq(
      ':',
      field('keyword', /[A-Z]+/),
      ':',
      field('value', /.+/),
    ),

    body: $ => /.+/,

    comment: $ => token(/#.*/),
  },
});