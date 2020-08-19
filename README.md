# aprs-monitor

This iOS app allows you to connect to a local TNC via WiFi.
I plan to extend support to the Kenwood TH-D74A via Bluetooth (once I get it--  the radio is backordered!   I thought ham radio was dead?)

It currently supports both iPad and iPhones. Eventually this app will also be a good candidate for MacOS X for Apple Silicon (Big Sir+) as it will run native on your Desktop!

## Overview

This open source project currently only supports talking to a KISS TNC.  I've only tested the code with Direwolf 1.4.  I plan on extending support to the Kenwood TH-D74A radio via bluetooth as supposedly it will output the APRS packets in KISS format.

This code was really written for me to be able to see what my radio is hearing without having to use something like YAAC or Xastir.  I'm a Mac guy and expect a certain level of interaction and graphics quality.  They are both fine apps but are not really native iOS or MacOS X apps and they don't act like it as well.  This app aims to fix that-  No need to launch the X-Window System or the JAVA subsystem.  Ok so the APRS icons are different, but should be instantly familiar.

There are many things that aren't complete yet.  Most noticably are the overlay symbols.  I have only implemented a few symbols mainly because I'm looking for high quality icons or I couldn't find a proper emoji or glyph to communicate the same icon as the standard APRS icon set.   I might just give up and use the standard set, but not without a fight first.  Let's move forward and stop using icons from DOS!  

Thank you for contributing to this project (that's a backwards way of saying, "please contribute to this project").  
It is not meant to replace the excellent APRS.fi iOS app.  It is also not meant to be the same type of application.  
APRS.fi can do a great deal more and can access the APRS-IS database full of packets and merge that info into one packet display. 
This app is simply a packet monitor-  in its current incarnation, it doesn't do much more than show you what your radio hears.  
It doesn't trace the path, doesn't show aloha circles, etc...  But it can with your help! ;-)


### History 

I could not get APRS.fi app to see my RPi bluetooth KISS port so I wrote my own app.  I think APRS.fi only supports the Mobilinkd TNC3.  
This first revision took a solid eight days of writing and this current feature set will be released as v1.0 on the AppStore (plus days of testing and bug fixing).  
I plan to add more features later depending on how many people find this app valuable or how much feedback I get.  (email me at support@folabs.com)

This code uses some of Direwolf's APRS packet decoding code which I heavily modified and used directly in my code.  All the code in the root directory of this project is not mine.  
I will add a page in the settings UI to list all open source information (this isn't done yet) most likely in v2 before someone notices.

There are no iOS apps that let you connect to a remote TNC.  There's APRSDroid on Android that I found which actually found my RPi on bluetooth but then crashed connecting to it, and subsequently crashed every launch thereafter.  I had to delete the app, plus I'm not an Android user.

I hope you enjoy the app-  you can purchase it on the Apple Appstore if you don't want to build it yourself.  If you aren't an Apple Developer, please remember you cannot run this code on your device without paying the yearly membership fee-  this is much greater than the cost of this software.  You can however run this code in the Simulator, it works fine there and doesn't require a membership fee.

73, K6LOT

![](https://raw.githubusercontent.com/crazypill/aprs-monitor/master/aprs-monitor.jpg)
