# oLv Demos


Info about oLv Demos

## ardourV1

### OSC controller for Ardour DAW

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


## demoV1

### Demo of many GUI elements including:

  * activate and deactivate elements (play with it)
  * switch between fullscreen and NOT
  * Size image, and use that to reset the viewPort
  * Various knobs, sliders, textboxes, droplists

## hello1

### Simple demo

## hello2

### Another simple demo

## hellomin

### A very minimal demo, maybe the most basic.

## oscCaster

### Sends OSC data on address, port

  * Defaults set, but can be changed
  * Click on 'Send OSC Msgs' to open the port, begin send
  * Deselecting this closes the port
  * Select the frequency of the messages

## oscMonV1

### monitors OSC messages on address, port

  * Defaults set, but can be changed
  * Click on 'OSC Server' to open the port, begin capture
  * Deselecting closes the port
  * Uses 'oLvoscT', the threaded server

## themesV1

### Themes is a color picker, and a theme color editor

  * Different preset themes can be selected in the Preset droplist
  * Move Presets to the color 'Quad' pallette
  * The palette can be set as the current theme
  * The buttons 'Print Color' and 'Print Palette Tbl' will output RGB tables that **oLvgui** can use
  * That color info is copied to the clipboard

## tinaV1

### tina is a tiny concertina-like instrument

*tina* sends OSC data to a Pure Data script, which converts it to MIDI data -> which is routed to the softsynth of your choice.

*tina* has it's own documention...