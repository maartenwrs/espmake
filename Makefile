# This Makefile is based on https://github.com/maartenwrs/espmake
# 
# A convenience c-preprocessor define _PROJTAG$(PROJTAG) is defined so that
# project-specific yaml can be written inside, for example, #if _PROJTAG_foo
# / #endif blocks, when PROJTAG is set to "foo".
# 
# A convenience c-preprocessor define _USER_$(USER) is defined so that
# personal yaml can be written inside, for example, #if _USER_maarten
# / #endif blocks, if your userid is 'maarten'.
#
# Please see https://github.com/maartenwrs/espmake/blob/main/README.md for more details.

MAIN	= main.yaml
SRCS	= $(wildcard *.yaml)

# the make rules below require yaml files to have .yaml suffixes.
ifneq (x$(suffix $(MAIN)),x.yaml)
  $(error "The suffix of $(MAIN) yaml file must be .yaml")
endif
ifeq ($(shell test -e $(MAIN) || echo -n no),no)
  $(error "$(MAIN) not found (MAIN=xxx.yaml argument intended?)")
endif

ifneq (x$(suffix $(MAIN)),x.yaml)
  $(error "The suffix of $(MAIN) yaml file must be .yaml")
endif

OUTDIR	= .
PROJTAG	= 0
PREFIX	= $(OUTDIR)/myProj_
PROJDIR	= $(PREFIX)$(PROJTAG)
CPPINCS = -I$(PROJDIR) -I.
CPPDEFS = -D_PROJTAG_$(PROJTAG)=1 -D_USER_$(USER)=1

_MAIN	= $(PROJDIR).yaml
_YAMLS	= $(addprefix $(PROJDIR)/,$(filter-out $(wildcard $(PREFIX)*.yaml),$(SRCS)))

DEHASH	= $(OUTDIR)/dehash/dehash
CPP	= gcc -x c -E -P -undef -nostdinc $(CPPINCS) $(CPPDEFS) 

all:	$(OUTDIR)/dehash $(_YAMLS) $(_MAIN)
	@echo "$(_MAIN) is up to date and ready for commands such as:"
	@echo "esphome config  $(_MAIN)"
	@echo "esphome compile $(_MAIN)"
	@echo "esphome upload  $(_MAIN)"

$(_MAIN) $(_YAMLS): $(OUTDIR)/dehash Makefile

$(_MAIN): $(PROJDIR)/$(MAIN) $(_YAMLS)
	@echo "Generating $@ from dehashed files in $(PROJDIR)/"
	$(CPP) -MD -MP -MT $@ -MF $<.d $< > $@

$(OUTDIR):
	-mkdir -p $@

$(PROJDIR):
	-mkdir -p $@

$(PROJDIR)/%.yaml: %.yaml
	$(DEHASH) --cpp --outdir $(PROJDIR) $<

-include $(wildcard $(PROJDIR)/*.d)

clean:
	rm -rf $(PROJDIR) $(_MAIN)

realclean: clean
	rm -rf $(OUTDIR)/dehash .esphome

.PHONY:    clean realclean update
.PRECIOUS: $(PROJDIR) $(OUTDIR) $(OUTDIR)/dehash

$(OUTDIR)/dehash:
	-@mkdir -p $(OUTDIR)
	cd $(OUTDIR); git clone git@github.com:maartenwrs/dehash

# pull dehash repo and this Makefile from github
update:
	-@if [ -d "$(OUTDIR)/dehash" ]; then 			\
		echo "Updating git repo $(OUTDIR)/dehash";	\
		cd $(OUTDIR)/dehash; git pull; 			\
	fi
	-@curl https://raw.githubusercontent.com/maartenwrs/espmake/main/Makefile >Makefile.new 2> /dev/null
	-@echo "Latest espmake Makefile downloaded as Makefile.new"
	-@echo "Changes from ./Makefile to latest espmake Makefile are:"
	-diff Makefile Makefile.new

