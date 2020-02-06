# heat-death
A pico-8 twin stick shooter. A compiled, playable version exists on https://gate.itch.io/heat-death

## Compiling
To compile for HTML, navigate to the /src folder in PICO-8 and run the following command:

```
export -f heat_death.html heat_death_game.p8 heat_death_tutorial.p8 heat_death_menu.p8
```

### Dual-stick and remappable controller support

Dual-stick and remappable controls are only supported when exporting to HTML.

To add remappable controller support and dual stick support to the game, after exporting to HTML, add "nfig_dualstick.js" to the output folder. Then edit the exported index.html and add the following lines right above the `</body>` close tag:

```html
<script
    data-players="4"
    data-no-button
    src="nfig_dualstick.js"></script>
```

This script works by hijacking PICO-8's normal input events and handling them in JS. By default, each stick on each controller is mapped to the following players' directional controls in PICO-8 seen in the table below. Thus, the dual stick controls only support 4 players max, since controller 1 uses player index 0's directional controls for the left stick, and player index 5's directional controls for the right stick.

|Controller Port|Left Stick Directional Input Index|Right Stick Directional Input Index|
|---:|---:|---:|
|1|0|4|
|2|1|5|
|3|2|6|
|4|3|7|

### Additional modifications for BBS release
To release this game on the PICO-8 BBS (https://www.lexaloffle.com/bbs/), all "load()" commands must be updated in each of .p8 files to point to the IDs used on the BBS. Instead of a passing a filename as the first argument to the load command, they will be formatted `"#like_this"`, where "like_this" is the ID of the cart you wish to load.

## JS File Liscense
The files in the js folder ("nfig.js" and "nfig_dualstick.js") are offered under the "unlicense" within that folder.

They are heavily modified versions of the files in this repo: https://github.com/codl/pico-nfig . My modifications to "nfig.js" were to make it work correctly with PICO-8 v0.1.12c and correct styling issues I saw Chrome for the HTML exporter in that version. "nfig_dualstick.js" is further modified to provide dual stick support. I offer no guarentee that these modifications will work correctly with your game, especially if you're exporting with an earlier or later version of PICO-8.