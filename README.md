# aprs-monitor

This iOS app allows you to connect to a local TNC via WiFi (and soon via Bluetooth to a Kenwood TH-D74A).  Eventually this app will also be a good candidate for MacOS X for Apple Silicon (Big Sir+).

## Overview

This open source project currently only supports talking to a KISS TNC.  I've only tested the code with Direwolf 1.4.  I plan on extending support to the Kenwood TH-D74A radio via bluetooth as supposedly it will output the APRS packets in KISS format.

This code was really written for me to be able to see what my radio is hearing without having to use something like YAAC or worse Xastir.  I'm a Mac guy and expect a certain level of interaction and graphics quality.  They are both fine apps but are not really native iOS or MacOS X apps.  This app aims to be that-  the APRS icons are different but should be instantly familiar.

There are many things that aren't complete yet.  Most noticably are the overlay symbols.  I have only implemented a few symbols mainly because I'm looking for high quality icons or I couldn't find a proper emoji or glyph to communicate the same icon as the standard APRS icon set.   I might just give up and use the standard set, but not without a fight first.  Of course, this being open source, you can go ahead and do that work for me!  Please be sure to make it a user settable preference as I like my icons better than the standard set.  I hope you do too.

Thank you for contributing to this project.  It is not meant to replace the excellent APRS.fi iOS app.  For some reason, I could not get that app to see my RPi bluetooth KISS port so I wrote my own app.  I've spent about a week solid writing this and this current feature set will be released as v1.0.  I plan to add more features later depending on how many people find this app valuable or how much feedback I get.  

There are no iOS apps that let you connect to a remote TNC.  There's APRSDroid on Android that I found which actually found my RPi but then crashed connecting to it, and subsequently crashed every launch thereafter.

I hope you enjoy the app-  you can purchase it on the Apple Appstore if you don't want to build it yourself.

73, K6LOT
