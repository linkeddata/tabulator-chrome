
SRC=$(wildcard *.coffee)
LIB=$(SRC:%.coffee=%.js)

.PHONY: coffee
coffee: $(LIB)

%.js: %.coffee
	coffee -bp $< > $@
