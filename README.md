# mit-scheme
MIT Scheme wrapped in JavaScript, and other things that should never exist. 

Scheme is so beautiful it scares some people away, so I made it more ugly by wrapping it in a Node.js duplex stream. Originally written for the [Ozymandias](https://github.com/joeltg/ozymandias) editor, but spun off for future perverse integrations.

```
sudo npm install -g --unsafe-perm mit-scheme
```

```
const MITScheme = require('mit-scheme');
const scheme = new MITScheme({scmutils: true});
scheme.pipe(process.stdout);
process.stdin.pipe(scheme);
```
```
;; evaluate expressions by writing them to the stream
;; don't forget an ending '\n'
> (* 3 4)
{"type": "value", "data": {"text": "12"}}

> (define (foo a b) (sqrt (+ (square a) (square b))))
{"type": "value","data": {"text": "foo", "pretty": "foo\n", "latex": "foo"}}

> (foo 3 4)
{"type": "value", "data": {"text": "5"}}

;; load with {scmutils: true} for symbolic fun
> (foo 'x 'y)
{
  "type": "value", 
  "data": {
    "text": "(*number* (expression (sqrt (+ (* x x) (* y y)))))",
    "pretty": "(sqrt (+ (expt x 2) (expt y 2)))\n",
    "latex": "\\sqrt{{x}^{2} + {y}^{2}}"
  }
}

;; even more fun
> (vector 5)
{
  "type": "value",
  "data": {
    "text": "#(5)",
    "pretty": "(up 5)\n",
    "latex": "\\left( \\begin{matrix} \\displaystyle{ 5}\\end{matrix} \\right)"
  }
}

;; stdout gets its own type
> (display "hello world")
{"type": "stdout", "data": "hello world"}
{"type": "value", "data": {"text": "No return value"}}

;; very fragile error handling framework
> fjdkalsjfa
{
  "type": "error",
  "data": {
    "message": "Unbound variable: fjdkalsjfa",
    "stack": [
      {"env": "#[unnamed-procedure]", "exp": "fjdkalsjfa\n"}
    ],
    "restarts": [
      {"name": "use-value", "report" :"Specify a value to use instead of fjdkalsjfa.", "arity": 1},
      {"name": "store-value", "report": "Define fjdkalsjfa to a given value.", "arity": 1},
      {"name": "abort", "report": "Return to read-eval-print level 1.", "arity": 0}
    ]
  }
}

;; index into the restart list to invoke "abort" 
> (2)
{"type": "stdout", "data": "\n;"}
{"type": "stdout", "data": "Abort!"}

;; custom graphics device called "canvas"
> (define win (make-graphics-device 'canvas))
{"type": "canvas", "data": {"action": "open", "id":0, "value": [0,300,300,0]}}
{"type": "value", "data": {"text": "win", "pretty": "win\n", "latex": "win"}}

> (graphics-draw-point win 100 100)
{"type": "canvas", "data": {"action": "draw_point", "id": 0, "value": [100, 100]}}
{"type": "value", "data": {"text": "No return value"}}

```
