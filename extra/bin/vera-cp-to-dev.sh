#!/usr/bin/env zsh

pushd -q ${HOME}/devel/vera/lib

ex_files=(*/*.ex)
devel_extra=${HOME}/devel/helen/_build/dev/rel/helen/extra-mods/always

rsync -a --delete-after $ex_files $devel_extra
