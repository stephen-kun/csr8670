# Top level makefile to build the kalimba libraries

# More high-level magic from here on in
ifneq (,$(BLUELAB))
include $(BLUELAB)/Makefile.rules
else

ifeq (,$(KAL_DIR))
$(error In a non-Bluelab build, an output location is required)
endif

include $(MAKE_DSP_DIR)/Makefile.dsp.$(HARDWARE)

# tools we need
kar         ?= $(TOOLS_DIR)/kar
kas         ?= $(TOOLS_DIR)/kas
recordflags ?= $(TOOLS_DIR)/recordflags
# standard tools we use
copyfile    ?= cp -f
del         ?= rm -f
mkdir       ?= mkdir -p

TARGET_CORES=$(HARDWARE)

endif

# directories to exclude
EXCLUDE_LIBS ?= 

# directories to build
# some build order is necessary due to library interdependencies so core, patch, cbops, codec and math must be built first
dirs ?=  core cbops patch codec math $(filter-out core patch cbops codec math $(EXCLUDE_LIBS) $(patsubst %/,%,$(sort $(dir $(wildcard */BROKEN)))),$(patsubst %/,%,$(sort $(dir $(wildcard */*.asm)))))


# library set to build for
LIB_SET ?= sdk

# which chips
TARGET_CORES ?= $(sort $(SUPPORTED_DSP_CORES))

# destination for result
KAL_DIR?=$(BL)/kalimba
ARCHITECTURE_DIR ?=$(KAL_DIR)/architecture



# Allow choice of which executables to use (so we can do easy regression testing
# of building the Kalimba libs), but default to the standard versions
KAS ?= $(kas)
KAR ?= $(kar)

.PHONY : all

$(shell $(mkdir) $(KAL_DIR)/lib_sets/$(LIB_SET))

INCLUDE_PATHS=-I$(realpath $(dir)) \
              -I$(KAL_DIR)/lib_sets/$(LIB_SET)/include/ \
              -I$(KAL_DIR)/external_includes/vm/ \
              -I$(KAL_DIR)/external_includes/firmware/ \
              -I$(ARCHITECTURE_DIR)/

# make sure we build the kalimba_messages.h and kalimba_standard_messages.h first (if we're building it)
all : $(KAL_DIR)/external_includes/firmware/kalimba_messages.h $(KAL_DIR)/external_includes/vm/kalimba_standard_messages.h


################################################################################
# Create rules to build a library
#
# $(1) - the source code to use
#
################################################################################
define rules
$(foreach hw,$(TARGET_CORES), \
  $(call rules_core,$(1),$(hw)) \
)
endef
# $(1) - the source code to use
# $(2) - the core to build for
define rules_core
ifeq ($(2),$(filter $(2),$(TARGET_CORES)))
########################################
# build targets
########################################
all : $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).a $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).link

output/$(dir)/$(2)/%.o : $(dir)/%.asm $(dir)/Makefile.lib headers_$(dir)
	$(mkdir) $$(dir $$@)
	$(KAS) $($(2)_kalasm3_flags) $(INCLUDE_PATHS) $(CURDIR)/$$< -o $$@

$(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).a : $(patsubst %.asm,output/$(dir)/$(2)/%.o,$(1))
	$(mkdir) $$(dir $$@)
	$(KAR) cr $$@ $$^
	$(recordflags) $(KAL_DIR)/lib_sets/$(LIB_SET)/built_from_$$(notdir $$(basename $$@)) $(CURDIR)

$(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).link : $(firstword $(wildcard $(dir)/$(dir).link.$(2) $(dir)/$(dir).link))
	$(copyfile) $$^ $$@

########################################
# clean targets
########################################
clean : clean_$(dir)_$(2)

clean_$(dir)_$(2) :
	$(del) $(patsubst %.asm,output/$(dir)/$(2)/%.o,$(1))
	$(del) $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).a
	$(del) $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(2)_arch_dir)/$(dir).link

endif

endef # rules_core


################################################################################
# Create rules to build a library variant
#
# $(1) - the library variant, debug, etc.
# $(2) - any flags to pass to assembler
# $(3) - the source code to use
################################################################################
define rules_variant
$(foreach hw,$(TARGET_CORES), \
  $(call rules_variant_core,$(1),$(2),$(3),$(hw)) \
)
endef
# $(1) - the library variant, debug, etc.
# $(2) - any flags to pass to assembler
# $(3) - the source code to use
# $(4) - the core to build for
define rules_variant_core
ifeq ($(4),$(filter $(4),$(TARGET_CORES)))
########################################
# build targets
########################################
all : $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).a $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).link

output/$(dir)/$(4)/$(1)/%.o : $(dir)/%.asm $(dir)/Makefile.lib headers_$(dir)
	$(mkdir) $$(dir $$@)
	$(KAS) $($(4)_kalasm3_flags) $(2) $(INCLUDE_PATHS) $(CURDIR)/$$< -o $$@

$(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).a : $(patsubst %.asm,output/$(dir)/$(4)/$(1)/%.o,$(3))
	$(mkdir) $$(dir $$@)
	$(KAR) cr $$@ $$^
	$(recordflags) $(KAL_DIR)/lib_sets/$(LIB_SET)/built_from_$$(notdir $$(basename $$@)) $(CURDIR)


$(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).link : $(firstword $(wildcard $(dir)/$(dir)_$(1).link.$(4) $(dir)/$(dir)_$(1).link $(dir)/$(dir).link.$(4) $(dir)/$(dir).link))
	$(copyfile) $$^ $$@

########################################
# clean targets
########################################
clean : clean_$(dir)_$(4)_$(1)

clean_$(dir)_$(4)_$(1) :
	$(del) $(patsubst %.asm,output/$(dir)/$(4)/$(1)/%.o,$(3))
	$(del) $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).a
	$(del) $(KAL_DIR)/lib_sets/$(LIB_SET)/$($(4)_arch_dir)/$(dir)_$(1).link

endif

endef # rules


################################################################################
# Create rules to copy header files
#
# $(1) - the headers
#
################################################################################
define header_rules

########################################
# build targets
########################################
headers_$(dir) : $(addprefix $(KAL_DIR)/lib_sets/$(LIB_SET)/include/,$(1))

$(KAL_DIR)/lib_sets/$(LIB_SET)/include/%.h : $(dir)/%.h
	$$(mkdir) $$(dir $$@)
	$$(copyfile) $(dir)/$$*.h $$@

# Like using 'touch', but we can't rely on that
headers_$(dir) :
	$(del) $$@
	$(recordflags) $$@

########################################
# clean targets
########################################
clean : clean_headers_$(dir)

clean_headers_$(dir) :
	$(del) $(addprefix $(KAL_DIR)/lib_sets/$(LIB_SET)/include/,$(1))
	$(del) headers_$(dir)

endef # header_rules

################################################################################
# some variables for library variants to use, flags, architecture sets
################################################################################
FL_DEBUG        = -DDEBUG_ON
FL_BASE_REG     = -DBASE_REGISTER_MODE
FL_PATCH        = -DPATCH_LIBS

KAL_ARCH3_CORES = dale gemini gordon oxygen purdey
KAL_ARCH5_CORES = rick

KAL_BASE_REG_CORES = $(KAL_ARCH3_CORES) $(KAL_ARCH5_CORES)


################################################################################
# "build" each library, this is where we actually do the work
################################################################################
$(foreach dir,$(dirs), \
  $(eval include $(dir)/Makefile.lib) \
)


ifneq (,$(KAL_MSG_DIR))
########################################
# build targets
########################################
$(KAL_DIR)/external_includes/firmware/kalimba_messages.h : $(KAL_MSG_DIR)/kalimba_messages.h
	$(mkdir) $(dir $@)
	sed -e "s/^#define.*KAL_MSG_\(.*\)$$/\.CONST \$$MESSAGE_\1;/" -e "s/^#define.*KAL_LONG_MSG_\(.*\)$$/\.CONST \$$LONG_MESSAGE_\1;/" $< >$@

########################################
# clean targets
########################################
clean : clean_kal_msg

clean_kal_msg :
	$(del) $(KAL_DIR)/external_includes/firmware/kalimba_messages.h

endif

# this creates a blank kalimba_standard_messages.h file so that #includes will work
$(KAL_DIR)/external_includes/vm/kalimba_standard_messages.h:
	$(mkdir) $(dir $@)
	echo // blank file >$@

