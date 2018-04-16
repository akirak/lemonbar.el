# lemonbar.el

[Lemonbar](https://github.com/LemonBoy/bar) integration for Emacs

## Features

This library starts lemonbar as an asynchronous process and updates its content from inside Emacs. This can be especially useful for users of [EXWM](https://github.com/ch11ng/exwm), because it allows you to display variables in Emacs via the bar. It can be considered as a screen-wide variant of modeline. 

## Prerequisites

- Emacs 25.1
- [Lemonbar](https://github.com/LemonBoy/bar)

## Configuration

Customize `lemonbar-output-template` variable to specify a template for your lemonbar. [This gist](https://gist.github.com/akirak/ba5fb9aeb8b2832e1346e88c1fa9add1) provides an example for feeding the system status from i3status to lemonbar.el.

Add `(lemonbar-start)` to your init.el.

## License

GPL v3
