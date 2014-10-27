# webapi-vim

An Interface to WEB APIs.

## Description

Currently this library supports the following protocols:

* Basic HTTP
* OAuth
* Atompub
* SOAP (in progress)
* XMLRPC
* MetaWeblog API

This library contains:

* XML Parser
* HTML Parser(Hack Way)
* JSON Parser
* BASE64 Hash Algorithm
* SHA1 Hash Algorithm
* HMAC HASH Algorithm
* Bit Operation Library
* Converter for "UTF-8 to Unicode"

## Installation

Copy the files in this library to your `.vim` directory. Alternatively, if you
use pathogen, copy this folder to your `.vim/bundle` directory.

## Requirements

You need the `curl` command, which can be downloaded from here: http://curl.haxx.se/

\*or\*

the `wget` command, available here: https://www.gnu.org/software/wget/

## Thanks

Yukihiro Nakadaira : http://sites.google.com/site/yukihironakadaira/

* autoload/base64.vim (I added small changes)
* autoload/hmac.vim
* autoload/sha1.vim

## License

Public Domain

## Project Authors

Yasuhiro Matsumoto (a.k.a mattn)
