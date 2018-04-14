# pjsua-static [![Build Status](https://travis-ci.org/probonopd/pjsua-static.svg?branch=master)](https://travis-ci.org/probonopd/pjsua-static)

[pjsua](http://www.pjsip.org/pjsua.htm) is an open source command line SIP user agent (softphone). This project compiles it as a static binary for ARM

## Usage

On a 32-bit ARM system where `aplay -l` and `arecord -l` are working, do the following:

```
rm -rf pjsip-apps* || true
wget https://github.com/probonopd/pjsua-static/releases/download/continuous/pjsip-apps-2.7.2-arm.tar.bz2
tar xf pjsip-apps*.tar.bz2 
./pjsip-apps/bin/pjsua-armv7l-unknown-linux-gnueabihf sip:wbdemo@conf.zipdx.com
# 0 is built-in usually
```

To check Polycom CX300:

```
# Polycom HD demo
./pjsip-apps/bin/pjsua-armv7l-unknown-linux-gnueabihf --capture-dev=7 --playback-dev=7 sip:wbdemo@conf.zipdx.com
# Send DTMF #
# Send DTMF 5
```
