// nfig - https://github.com/codl/pico-nfig
// please don't look at my code it's bad

var pico8_buttons = pico8_buttons || [0, 0, 0, 0, 0, 0, 0, 0];

function nfig(settings){
    console.log("nfig initialising...");

    const storage_key = "gate88-heat-death-controller-mappings";

	var observer = new MutationObserver(function(mutations) {
		document.removeEventListener("keydown", SDL.receiveEvent);
        document.removeEventListener("keyup", SDL.receiveEvent);
        //really stupid hack to make the next call that p8_update_gamepads makes to requestAnimationFrame() pass an empty function
        p8_update_gamepads = function(){};
        var menuButtons = document.getElementById("menu_buttons").style.width = "1px";
        document.getElementById("p8b_controls").onclick = nfig_toggle;
	    observer.disconnect();
	});

	var target = document.getElementById("p8_playarea");
	observer.observe(target, { attributes : true, attributeFilter : ['style'] });

    const buttons = ["left", "right", "up", "down", "o", "x", "r_left", "r_right", "r_up", "r_down"]
    const bitmap = {
        "left": 1,
        "right": 2,
        "up": 4,
        "down": 8,
        "o": 16,
        "x": 32,
        "pause": 64
    }
    const bitmap2 = {
        "r_left": 1,
        "r_right": 2,
        "r_up": 4,
        "r_down": 8,
    }
    const default_bindings = {
     "e": [0, "up"],
     "d": [0, "down"],
     "s": [0, "left"],
     "f": [0, "right"],

     "arrowup": [0, "up"],
     "arrowdown": [0, "down"],
     "arrowleft": [0, "left"],
     "arrowright": [0, "right"],

     "z": [0, "o"],
     "c": [0, "o"],
     "x": [0, "x"],
     " ": [0, "o"],

     "i": [4, "up"],
     "k": [4, "down"],
     "j": [4, "left"],
     "l": [4, "right"],

     "escape": [0, "pause"],
     "p": [0, "pause"]
    };
    for(let i=0; i < 4; i++){
        default_bindings[`pad_generic:${i}:button:0:+`] = [i, "x"];
        default_bindings[`pad_generic:${i}:button:1:+`] = [i, "o"];
        default_bindings[`pad_generic:${i}:axis:0:-`] = [i, "left"];
        default_bindings[`pad_generic:${i}:axis:0:+`] = [i, "right"];
        default_bindings[`pad_generic:${i}:axis:1:-`] = [i, "up"];
        default_bindings[`pad_generic:${i}:axis:1:+`] = [i, "down"];

        default_bindings[`pad_standard:${i}:button:12:+`] = [i, "up"];
        default_bindings[`pad_standard:${i}:button:13:+`] = [i, "down"];
        default_bindings[`pad_standard:${i}:button:14:+`] = [i, "left"];
        default_bindings[`pad_standard:${i}:button:15:+`] = [i, "right"];
        default_bindings[`pad_standard:${i}:button:0:+`] = [i, "x"];
        default_bindings[`pad_standard:${i}:button:1:+`] = [i, "o"];
        default_bindings[`pad_standard:${i}:button:2:+`] = [i, "o"];
        default_bindings[`pad_standard:${i}:button:3:+`] = [i, "x"];
        default_bindings[`pad_standard:${i}:axis:2:-`] = [i+4, "left"];
        default_bindings[`pad_standard:${i}:axis:2:+`] = [i+4, "right"];
        default_bindings[`pad_standard:${i}:axis:3:-`] = [i+4, "up"];
        default_bindings[`pad_standard:${i}:axis:3:+`] = [i+4, "down"];

        default_bindings[`pad_standard:${i}:button:9:+`] = [i, "pause"];
    }
    window.default_bindings = default_bindings;
    let bindings = Object.assign({}, default_bindings);
    try {
        let saved = JSON.parse(localStorage.getItem(storage_key));
        if(saved && typeof saved == "object") {
            bindings = saved;
            console.log("nfig successfully loaded saved mappings");
        }
    } catch (e) {
        console.log(e);
    }

    const AXIS_DEADZONE = .45;


    let max_players = Math.floor(settings.players-0 || 2);

    if(!(max_players <= 8 && max_players >= 1)){
        console.error("nfig: data-players is not between 1 and 8! resetting to 2")
        max_players = 2;
    }

    function key(e){
        //console.log(e);
        if(e.key == "Enter" || e.key.toLowerCase() == "p"){
            return SDL.receiveEvent.call(this, e);
        }
        if(e.ctrlKey){
            return
        }

        if(e.type == "keydown" && is_mapping){
            add_mapping(e.key.toLowerCase());
            e.preventDefault();
        }

        else {
            let binding = bindings[e.key.toLowerCase()];
            if(binding){
                let [player, button] = binding;
                if(e.type == "keydown"){
                    pico8_buttons[player] |= bitmap[button];
                } else if(e.type == "keyup"){
                    pico8_buttons[player] &= ~bitmap[button];
                }
                e.preventDefault();
                render();
            }
        }
    }
    window.addEventListener("keydown", key);
    window.addEventListener("keyup", key);

    function add_mapping(key){
        let player = player_el.value;
        var p = player;
        var m = is_mapping;
        if (is_mapping.startsWith("r_")) {
            p = parseInt(p)+4;
            p = p.toString();
            m = is_mapping.substring(2);
        }
        bindings[key] = [p, m];
        if(mapping_all){
            let next = buttons.indexOf(is_mapping) + 1;
            if(next >= buttons.length){
                is_mapping = null;
            }
            else {
                is_mapping = buttons[next];
            }
        }
        else {
            is_mapping = null;
        }
        localStorage.setItem(storage_key, JSON.stringify(bindings));
        render();
    }

    function on_pad(key, pad, control_type, control_index, direction, is_pressed, no_generics){
        //console.log(key, is_pressed);
        if(is_mapping && is_pressed){
            add_mapping(key);
        } else {
            let binding = bindings[key];
            if(binding){
                let [player, button] = binding;
                if(button == "pause"){
                    player = 0;
                }
                if(is_pressed){
                    pico8_buttons[player] |= bitmap[button];
                } else {
                    pico8_buttons[player] &= ~bitmap[button];
                }
                render();
                return true;
            } else if(!no_generics) {
                let success = false;
                if(pad.mapping){
                    let mapping_key = key.replace(/^pad:/, `pad_${pad.mapping}:`);
                    success = on_generic_pad(mapping_key, is_pressed);
                }
                if(!success){
                    let generic_key = `pad_generic:${pad.index%max_players}:${control_type}:${control_index % 2}:${direction}`
                    on_generic_pad(generic_key, is_pressed);
                }
            }
        }
    }

    function on_generic_pad(key, is_pressed){
        return on_pad(key, null, null, null, null, is_pressed, true);
    }

    const css = document.createElement("link");
    css.rel="stylesheet";
    css.href="data:text/css;base64,Lm5maWctcGFuZWx7cG9zaXRpb246YWJzb2x1dGU7cmlnaHQ6MDtib3R0b206MDt3aWR0aDo2MDBweDtiYWNrZ3JvdW5kLWNvbG9yOnJnYmEoOTUsODcsNzksMC45KTtjb2xvcjp3aGl0ZTtmb250LWZhbWlseTpWZXJkYW5hLHNhbnMtc2VyaWY7Zm9udC1zaXplOjlwdDtwYWRkaW5nOjZweDttYXJnaW46LTNweDt0cmFuc2Zvcm06dHJhbnNsYXRleSgxMDAlKTt0ZXh0LWFsaWduOmxlZnR9Lm5maWctcGFuZWwuc2hvd257dHJhbnNmb3JtOnRyYW5zbGF0ZXkoMCk7dHJhbnNpdGlvbjp0cmFuc2Zvcm0gMzAwbXN9Lm5maWctY29udGFpbmVye292ZXJmbG93OmhpZGRlbjtwb3NpdGlvbjpyZWxhdGl2ZX0jbmZpZy1jbG9zZXtkaXNwbGF5OmlubGluZS1ibG9jaztmbG9hdDpyaWdodH0jbmZpZy1jb250cm9sbGVye21heC13aWR0aDo0MjBweDtmbG9hdDpyaWdodDtjbGVhcjpyaWdodH0jbmZpZy1jb250cm9sbGVyIGcgcGF0aHtmaWxsOndoaXRlfSNuZmlnLWNvbnRyb2xsZXIgZy5tYXBwaW5nIHBhdGh7ZmlsbDpvcmFuZ2V9I25maWctY29udHJvbGxlciBnLnByZXNzZWQgcGF0aHtmaWxsOnBpbmt9Lm5maWctbGVmdHttYXJnaW46MWVtfQ==";
    document.body.appendChild(css);

    const container_el = document.createElement("div");
    container_el.classList.add("nfig-container");

    const canvas = document.getElementById("canvas");

    const main_section = canvas.parentNode
    main_section.replaceChild(container_el, canvas);
    container_el.appendChild(canvas);

    // PICO-8 Styler compat. That br isn't there in Styler
    let br = main_section.querySelector("br");
    if(br){
        main_section.removeChild(br);
    }

    const panel_el = document.createElement("div");
    panel_el.classList.add("nfig-panel");

    let panel_contents = '<div id="nfig-title">Remap controls <button id="nfig-close">Done</button></div>';

    panel_contents += '<svg id="nfig-controller" viewBox="0 0 360 148.0124" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:se="http://svg-edit.googlecode.com"><g data-nfig-btn="left" id="svg_1"> <path d="m28.3465,60.3465l27.3195,0l0,27.3195l-27.3195,0l0,-27.3195zm7.327,13.66l10.798,6.782l0,-13.564l-10.798,6.782z" id="svg_2"/> <rect fill-opacity="0" height="28" id="svg_3" width="28" x="28" y="60"/> </g> <g data-nfig-btn="right" id="svg_4"> <path d="m119.666,60.3465l-27.3195,0l0,27.3195l27.3195,0l0,-27.3195zm-7.327,13.66l-10.798,6.782l0,-13.564l10.798,6.782z" id="svg_5"/> <rect fill-opacity="0" height="28" id="svg_6" width="28" x="92" y="60"/> </g> <g data-nfig-btn="up" id="svg_7"> <path d="m60.3465,28.3465l0,27.3195l27.3195,0l0,-27.3195l-27.3195,0zm13.66,7.327l6.782,10.798l-13.564,0l6.782,-10.798z" id="svg_8"/> <rect fill-opacity="0" height="28" id="svg_9" width="28" x="60" y="28"/> </g> <g data-nfig-btn="down" id="svg_10"> <path d="m60.3465,119.666l0,-27.3195l27.3195,0l0,27.3195l-27.3195,0zm13.66,-7.327l6.782,-10.798l-13.564,0l6.782,10.798z" id="svg_11"/> <rect fill-opacity="0" height="28" id="svg_12" width="28" x="60" y="92"/> </g> <g data-nfig-btn="o" id="svg_13"> <path d="m142.6867,60.3465l0,27.3195l27.3195,0l0,-27.3195l-27.3195,0zm13.6594,6.129c4.1375,0 7.5312,3.393 7.5312,7.5304c0,4.1372 -3.3937,7.5303 -7.531,7.5303c-4.1374,0 -7.5305,-3.393 -7.5305,-7.5304c0,-4.1375 3.393,-7.5305 7.5304,-7.5305l-0.0001,0.0002zm0,3.6666c-2.1556,0 -3.8636,1.7082 -3.8636,3.864c0,2.1555 1.708,3.8636 3.8637,3.8636c2.1558,0 3.864,-1.708 3.864,-3.8637c0,-2.1558 -1.7082,-3.864 -3.864,-3.864l-0.0001,0.0001z" id="svg_14"/> <rect fill-opacity="0" height="28" id="svg_15" width="28" x="142" y="60"/> </g> <g data-nfig-btn="x" id="svg_16"> <path d="m188.3465,60.3465l0,27.3195l27.3195,0l0,-27.3195l-27.3195,0zm7.5864,5.431a1.948,1.948 0 0 1 1.3888,0.6108l4.684,4.8218l4.685,-4.8217a1.948,1.948 0 0 1 1.33,-0.6087a1.948,1.948 0 0 1 1.4636,3.323l-4.763,4.9033l4.763,4.9025a1.948,1.948 0 1 1 -2.7937,2.715l-4.6848,-4.8225l-4.6842,4.8224a1.948,1.948 0 1 1 -2.7944,-2.715l4.763,-4.9025l-4.763,-4.9035a1.948,1.948 0 0 1 1.4055,-3.325l0.0002,0.0001z" id="svg_17"/> <rect fill-opacity="0" height="28" id="svg_18" width="28" x="188" y="60"/> </g> <g data-nfig-btn="r_left" id="svg_40"> <path d="m240.8465,60.75269l27.3195,0l0,27.3195l-27.3195,0l0,-27.3195zm7.327,13.66l10.798,6.782l0,-13.564l-10.798,6.782z" id="svg_41"/> <rect fill-opacity="0" height="28" id="svg_42" width="28" x="240.5" y="60.40619"/> </g> <g data-nfig-btn="r_right" id="svg_37"> <path d="m332.166,60.75269l-27.3195,0l0,27.3195l27.3195,0l0,-27.3195zm-7.327,13.66l-10.798,6.782l0,-13.564l10.798,6.782z" id="svg_38"/> <rect fill-opacity="0" height="28" id="svg_39" width="28" x="304.5" y="60.40619"/> </g> <g data-nfig-btn="r_up" id="svg_34"> <path d="m272.8465,28.75269l0,27.3195l27.3195,0l0,-27.3195l-27.3195,0zm13.66,7.327l6.782,10.798l-13.564,0l6.782,-10.798z" id="svg_35"/> <rect fill-opacity="0" height="28" id="svg_36" width="28" x="272.5" y="28.40619"/> </g> <g data-nfig-btn="r_down" id="svg_31"> <path d="m272.8465,120.07219l0,-27.3195l27.3195,0l0,27.3195l-27.3195,0zm13.66,-7.327l6.782,-10.798l-13.564,0l6.782,10.798z" id="svg_32"/> <rect fill-opacity="0" height="28" id="svg_33" width="28" x="272.5" y="92.40619"/></g></svg>';

    panel_contents += '<div class="nfig-left">';
    if(max_players <= 1){
        panel_contents += '<input id="nfig-player" type="hidden" value="0"></input>';
    } else {
        panel_contents += '<select id="nfig-player">';
        for(let i = 0; i < max_players; i++){
            panel_contents += '<option value=' + i + (i==0?' selected':'') + '>Player ' + (i+1) + '</option>';
        }
        panel_contents += '</select>';
    }

    panel_contents += '<p id="nfig-status"></p>';

    panel_contents += '<div id="nfig-actions"><button id="nfig-cancel">Cancel</button> <button id="nfig-remapall">Remap all</button> <button id="nfig-reset">Restore defaults</button></div>';

    panel_contents += '</div>';

    panel_el.innerHTML = panel_contents;
    container_el.appendChild(panel_el);

    let is_mapping, mapping_all;

    const svg_buttons = Array.from(panel_el.querySelectorAll("svg g"));
    for(let button of svg_buttons){
        // switch this back when firefox 51 comes out
        //let which = button.dataset.nfigBtn;
        let which = button.getAttribute("data-nfig-btn");
        button.addEventListener("click", e => {
            is_mapping = which;
            mapping_all = false;
            render();
        });
    }

    let status_el = panel_el.querySelector("#nfig-status");

    function render(){
        let player = player_el.value - 0;
        let cancel_el = panel_el.querySelector("#nfig-cancel");
        let status = "Click any button to remap it."
        if(is_mapping){
            status = "Press a key or a gamepad button for " + is_mapping;
        }
        for(let button of svg_buttons){
            // switch this back when firefox 51 comes out
            //let which = button.dataset.nfigBtn;
            let which = button.getAttribute("data-nfig-btn");
            var r_player = player;
            var b = bitmap;
            if (which.startsWith("r_")) {
                r_player = player+4;
                b = bitmap2;
            }
            button.classList.toggle("mapping", is_mapping && which == is_mapping)
            button.classList.toggle("pressed", pico8_buttons[r_player] & b[which])
        }
        cancel_el.style.display = is_mapping ? "inline" : "none";
        status_el.innerHTML = status;
    }

    function cancel(){
        is_mapping = null;
        render();
    }

    panel_el.querySelector("#nfig-cancel").addEventListener("click", cancel);
    let player_el = panel_el.querySelector("#nfig-player")
    player_el.addEventListener("change", cancel);

    function toggle(e){
        if(e){
            e.preventDefault();
            // prevent focus from staying on the "Done" button
            e.target.blur();
        }
        cancel();
        panel_el.classList.toggle("shown");
    }

    window.nfig_toggle = toggle;

    panel_el.querySelector("#nfig-close").addEventListener("click", toggle);

    panel_el.querySelector("#nfig-remapall").addEventListener("click", () => {
        is_mapping = buttons[0];
        mapping_all = true;
        render();
    });

    panel_el.querySelector("#nfig-reset").addEventListener("click", () => {
        cancel();
        bindings = Object.assign({}, default_bindings);
        status_el.innerHTML = "Defaults restored."; // mmm gross
    })

    if(typeof settings.noButton == "undefined"){
        const config_button = document.querySelectorAll(".pico8_el")[4];
        config_button.innerHTML = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4QELDRogeDaFdgAAAHxJREFUSMdjYBjqgBGXxP+PL+BMQmpRDOSXQOEz0doHRFvAyC+B4TqqWkAuYMES5uguZ4TK/yc2/gbGB0SkJnQXE5W6Bk8qIhb8//gCJT6Z6JaTsaQSqpg9oKmIES21kOZ8aK4fEB8wUtMnA+KD/9Rw+aAoi/4PyqJi+AEAK5Ud5NJbqZQAAAAASUVORK5CYII=" width="12" height="12"> Remap';
        config_button.addEventListener("click", toggle);
    }

    let pad_status_prev = {};
    function poll_gamepads(){
        requestAnimationFrame(poll_gamepads);


        if(!window.navigator || (!navigator.getGamepads && !navigator.webkitGetGamepads)){ return }

        var gps = navigator.getGamepads() || navigator.webkitGetGamepads();

        let pad_status = {};

        for(gamepad of gps){
            if(!gamepad){ continue; }
            for(let i = 0; i < gamepad.axes.length; i++){
                let key = `pad:${gamepad.index}:axis:${i}`;

                let pluskey = key + ":+";
                pad_status[pluskey] = gamepad.axes[i] > AXIS_DEADZONE;

                if(pad_status_prev[pluskey] != pad_status[pluskey]){
                    on_pad(pluskey, gamepad, "axis", i, "+", pad_status[pluskey])
                }

                let minuskey = key + ":-";
                pad_status[minuskey] = gamepad.axes[i] < -AXIS_DEADZONE;

                if(pad_status_prev[minuskey] != pad_status[minuskey]){
                    on_pad(minuskey, gamepad, "axis", i, "-", pad_status[minuskey])
                }
            }
            for(let i = 0; i < gamepad.buttons.length; i++){
                let key = `pad:${gamepad.index}:button:${i}:+`;
                pad_status[key] = gamepad.buttons[i].pressed;

                if(pad_status_prev[key] != pad_status[key]){
                    on_pad(key, gamepad, "button", i, "+", pad_status[key])
                }
            }
        }
        pad_status_prev = pad_status;
        window.pad_status = pad_status;
    }

    poll_gamepads();

    render();

    console.log("cool. let's play some video games");
}

(() => {
    let settings = document.currentScript.dataset;
    window.addEventListener("DOMContentLoaded", () => nfig(settings));
})();
