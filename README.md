# mit-scheme
MIT Scheme wrapped in JavaScript

```
const {MITScheme, paths} = require('mit-scheme');
const scheme = new MITScheme();
scheme.pipe(process.stdout);
process.stdin.pipe(scheme);
```
```
> (* 3 4)
{
  "type": "value",
  "data": ["#| 12 |#"]
}

> (vector 1 2 3)
{
  "type": "value",
  "data": [
    "#|\n(up 1 2 3)\n|#",
    "\\boxit{ $$\\left( \\matrix{ \\displaystyle{ 1} \\cr \\cr \\displaystyle{ 2} \\cr \\cr \\displaystyle{ 3}} \\right)$$}"
  ]
}

> (pp "hello world")
{"type": "stdout", "data": "\"hello world\"\n"}
{"type": "value", "data": ["#| No return value |#"]}

> fjdsklafs
{
  "type": "error",
  "data": [
    "Unbound variable: fjdsklafs",
    [
      ["use-value", "Specify a value to use instead of fjdsklafs.", 1],
      ["store-value", "Define fjdsklafs to a given value.", 1],
      ["abort", "Return to read-eval-print level 1.", 0]
    ],
    [
      {
        "env": "#[unnamed-procedure]",
        "exp": "fjdsklafs\n"
      }
    ]
  ]
}

> (graphics-draw-point (make-graphics-device #f) 0 0)
{"type": "canvas", "data": ["open", 1, [0,300,300,0]]}
{"type": "canvas", "data": ["draw_point",1,[0,0]]}
```
