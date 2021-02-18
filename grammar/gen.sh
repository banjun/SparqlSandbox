#!/bin/sh
which antlr || brew install antlr
curl -O https://raw.githubusercontent.com/antlr/grammars-v4/master/sparql/Sparql.g4
antlr -Dlanguage=Swift Sparql.g4
