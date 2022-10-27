# FullControlX

FullControlX is the official Open Source "spinoff" of the commercial app [FullControl](https://fullcontrol.cescobaz.com).
It is a web remote controller for you PC/Mac, it works, at the moment, for Linux and MacOS.

Features:

* Keyboard based on a configured layout
* Mouse with multitouch support for movement, click, double click, right click, scroll and drag
* Special keyboard command: volume up/down, mute, play/pause, back, forward, brightness up/down and arrows

## Repository structure

* `fcxd` (FullControlX Driver) contains C and Objective-C code for operate directly with the specific OS API (only macos at the moment)
* `fcx-web` (FullControlX WebApp) contains an Elixir Phoenix LiveView WebApp
