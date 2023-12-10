#!/bin/bash

# for ubuntu / debian ! Should really test for this !

sudo apt install -y cpanminus

sudo cpanm Math::Prime::Util IO::Socket::INET Nice::Try Exception Test::Most
