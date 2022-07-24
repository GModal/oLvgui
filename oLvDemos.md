# oLv Demos


Info about oLv Demos

Projects with (OSC) utilize the **oLvosc** (and some **oLvoscT**) modules

## ardourV1

### OSC controller for Ardour DAW (OSC)

  * Sends OSC data on port 3819 (Ardour standard port)
  * Receives OSC data on port 8000
  * Set Reply port on Ardour:
    * Preferences->control surfaces->Open Sound Control->Show Protocol Settings
        * Control Protocol Settings Dialog -> Reply Manual Port: 8000
        * Also in 'Default Strip Types' Dialog check:
            * Audio Tracks
            * MIDI Tracks
            * Control Masters
        * In 'Default Feedback' Dialog check:
            * Strip Buttons
            * Master Sections
            * Play Head Position as Bar and Beat

  * Uses the **oLvoscT** threaded server

The 'Query' button should be pressed after starting (assuming Ardour is running). It will load the current tracks, and set Ardour to send it's data.

## demoV1

### Demo of many GUI elements including:

  * activate and deactivate elements (play with it)
  * switch between fullscreen and NOT
  * Size image, and use that to reset the viewPort
  * Various knobs, sliders, textboxes, droplists

## hello1

*Simple demo*

## hello2

*Another simple demo*

## hellomin

*A very minimal demo, maybe the most basic.*

## oscCaster

### Sends OSC test data to address, port (OSC)

  * Defaults set, but can be changed
  * Click on 'Send OSC Msgs' to open the port, begin send
  * Deselecting this closes the port
  * Select the frequency of the messages

## oscMonV1

### Monitors OSC messages on address, port (OSC)

  * Defaults set, but can be changed
  * Click on 'OSC Server' to open the port, begin capture
  * Deselecting closes the port

Uses 'oLvoscT', the threaded OSC server (LÖVE only) which is much more reliable for receiving OSC data packets.

## themesV1

### Themes is a color picker, and a theme color editor

  * Different preset themes can be selected in the Preset droplist
  * Move Presets to the color 'Quad' pallette
  * The palette can be set as the current theme
  * The buttons 'Print Color' and 'Print Palette Tbl' will output RGB tables that **oLvgui** can use
  * That color info is copied to the clipboard

## tinaV1

### tina is a tiny concertina-like instrument (OSC)

Like a concertina, *tina* is a two-handed performance instrument.

*tina* sends OSC data to a **Pure Data** script, which converts it to MIDI data -> which is routed to the softsynth of your choice.

*tina* has it's own documention...

  * *tina* is the most definitive demonstration of the **panel** element, and it's interactive capabilities
  * As noted, it uses **Pure Data** to convert the OSC data to a MIDI stream (and lessen the OSC network load)