# Top level makefile to build the BlueLab3 libraries
# JBS, May 2005

# SDK_LIBS is usually passed in from hostbuild, but if not then build them all
SDK_LIBS ?= $(filter-out $(patsubst %/,%,$(sort $(dir $(wildcard */BROKEN)))),$(patsubst %/,%,$(sort $(dir $(wildcard */*.h)))))

dirs = $(SDK_LIBS)

# It's all high-level magic from here on in
# Pay no attention to the man behind the curtain.

# Check if we've been told to ship broken libraries, and refuse
broken := $(wildcard $(addsuffix /BROKEN,$(dirs)))
ifneq (,$(broken))
$(error Refusing to install libraries marked as broken: $(patsubst %/,%,$(dir $(broken))))
endif

build :: no_ble header

install :: build helpers

install-shim :: install

include $(BLUELAB)/Makefile.rules

define get_aliases_and_variants

ALIAS:= $(1)
#set ALIAS by default to dir name, so that if there are no aliases the foreach loop will still happen once
VARIANTS:=

-include $(1)/VARIANTS

endef

define header_rules
# $(1) = directory containing source, whose name is usually the library name and header name (e.g. a2dp)
# $(2) = library alias (e.g. a2dp when the dir is actually called ad2p_new)

hdr_$(1) := $$(call profiles_inc_dir,$$(LIBRARY_VERSION))/$(2).h
no_ble_$(1) := $$(patsubst $(1)/%_no_ble.h,$$(call profiles_inc_dir,$$(LIBRARY_VERSION))/%_no_ble.h,$$(wildcard $(1)/$(1)_no_ble.h))
par_$(1) := $$(addsuffix .c,$$(basename $$(wildcard $(1)/*.parse)))
src_$(1) := $$(par_$(1)) $$(filter-out $$(par_$(1)) $(1)/main.c,$$(wildcard $(1)/*.c))
all_srcs += $$(src_$(1))
all_hdrs += $$(hdr_$(1))

header :: $$(hdr_$(1)) $$(patsubst %.c,%.h,$$(par_$(1)))

$$(hdr_$(1)) : $(1)/$(2).h
	$$(mkdir) $$(dir $$@)
	$$(copyfile) $$^ $$@
    
no_ble :: $$(no_ble_$(1))

$$(no_ble_$(1)) : $(1)/$(2)_no_ble.h
	$$(mkdir) $$(dir $$@)
	$$(copyfile) $$^ $$@    

shim_$(1) := $$(patsubst $(1)/%.h,$$(call profiles_inc_dir,$$(LIBRARY_VERSION))/%.h,$$(wildcard $(1)/$(1)_shim.h))

# Internal CSR target for shim code for library tests
install :: $$(shim_$(1))

$$(shim_$(1)) : $(1)/$(1)_shim.h
	$$(mkdir) $$(dir $$@)
	$$(copyfile) $$^ $$@

ifneq (,$$(par_$(1)))
.PRECIOUS : $$(par_$(1))

clean ::
	$$(del) $$(par_$(1)) $$(addsuffix .h, $$(basename $$(par_$(1))))
endif

endef # header_rules

define variant_rules
# $(1) = directory containing source, whose name is usually the library name (e.g. a2dp)
# $(2) = variant (e.g. debug)
# $(3) = variant with underscore prepended

# Make CFLAGS unique across libraries
CFLAGS_$(1)_$(2) := $$(strip $$(CFLAGS$(3)))
# Stop them bleeding across into other libraries
CFLAGS$(3)       :=

endef # variant_rules

define object_rules
# $(1) = directory containing source, whose name is usually the library name (e.g. a2dp)
# $(2) = variant (e.g. debug)
# $(3) = variant with underscore prepended
# $(4) = execution mode
# $(5) = library alias (e.g. a2dp when the dir is actually called ad2p_new)

obj_$(1)_$(2)_$(4)  := $$(patsubst $(1)/%.c,$(1)/$(2)/$(4)/%.o,$$(src_$(1)))

ifneq (,$$(obj_$(1)_$(2)_$(4)))

dep_$(1)_$(2)_$(4) := $$(call dependencies, $$(obj_$(1)_$(2)_$(4)))
lib_$(1)_$(2)_$(4) := $$(call lib_dir,$(4),$(LIBRARY_VERSION))/lib$(5)$(3).a

build :: $$(obj_$(1)_$(2)_$(4))

clean ::
	$$(del) $$(lib_$(1)_$(2)_$(4))
	$$(del) $$(obj_$(1)_$(2)_$(4)) 
	$$(del) $$(dep_$(1)_$(2)_$(4))
	$$(del) $(1)/$(2)/depend/flags.compile

install :: $$(lib_$(1)_$(2)_$(4))

$$(lib_$(1)_$(2)_$(4)) : $$(obj_$(1)_$(2)_$(4))
	$$(mkdir) $$(dir $$@)
	$$(ar) cr $$@ $$^

$$(obj_$(1)_$(2)_$(4)) : $$(hdr_$(1))

$(1)/$(2)/$(4)/%.o : $(1)/%.c $(1)/$(2)/$(4)/depend/flags.compile
	$$(call docompile,$$(CFLAGS_$(1)_$(2)),$(4))

-include $$(dep_$(1)_$(2)_$(4)) $(1)/$(2)/$(4)/dummy.force

$(1)/$(2)/$(4)/dummy.force :
	@$$(mkdir) $(1)/$(2)/$(4)/depend
	@$$(recordflags) $(1)/$(2)/$(4)/depend/flags.compile $$(compileflags) $$(4) $$(CFLAGS_$(1)_$(2))
endif

endef # object_rules

helper_directory := $(call profiles_inc_dir,$(LIBRARY_VERSION)/helpers)

define get_helpers
# $(1) - library name

src_dir_$(1)  := $(1)/helpers
dest_dir_$(1) := $(helper_directory)/$(1)

helpers_needed_$(1) := $$(patsubst $$(src_dir_$(1))/%,%,$$(wildcard $$(src_dir_$(1))/*))
helpers_exist_$(1)  := $$(patsubst $$(dest_dir_$(1))/%,%,$$(wildcard $$(dest_dir_$(1))/*))
helpers_to_add_$(1) := $$(addprefix $$(dest_dir_$(1))/,$$(helpers_needed_$(1)))

helpers_to_remove += $$(addprefix $$(dest_dir_$(1))/,$$(filter-out $$(helpers_needed_$(1)),$$(helpers_exist_$(1))))

helpers :: $$(helpers_to_add_$(1))

$$(helpers_to_add_$(1)) : $$(dest_dir_$(1))/% : $(1)/helpers/%
	$(mkdir) $$(dir $$@)
	$(copyfile) $$^ $$@

endef #get_helpers

helpers :: | cleanup

cleanup ::
	$(del) $(helpers_to_remove)

$(foreach d,$(dirs), \
  $(eval $(call get_aliases_and_variants,$(d))) \
  $(foreach a,$(ALIAS), \
    $(eval $(call header_rules,$(d),$(a))) \
    $(eval $(call variant_rules,$(d),default,)) \
    $(eval $(call get_helpers,$(d))) \
    $(foreach v,$(VARIANTS), \
      $(eval $(call variant_rules,$(d),$(v),_$(v)))) \
    $(foreach m,$(SUPPORTED_EXECUTION_MODES), \
      $(eval $(call object_rules,$(d),default,,$(m),$(a))) \
      $(foreach v,$(VARIANTS), \
      $(eval $(call object_rules,$(d),$(v),_$(v),$(m),$(a)))))))


doc_hdrs := $(sort $(wildcard $(addprefix $(firmware_inc_dir)/,*.h */*.h */*/*.h) $(all_hdrs)))

doc_header_stamp_file = $(BLUELAB)/../doc/reference/header_files

$(shell $(mkdir) $(dir $(doc_header_stamp_file)))
$(shell $(recordflags) $(doc_header_stamp_file) $(doc_hdrs))

doxygen : $(BLUELAB)/../doc/reference/html/index.html

$(BLUELAB)/../doc/reference/html/index.html : $(doc_hdrs) $(doc_header_stamp_file)
	$(MAKE) -C $(BLUELAB)/doc

# CSR internal target, requires PC-Lint 8.0

export BLUELAB

lint : header $(all_srcs)
	$(lint) -i../../../tools/pclint $(lintflags) $(all_srcs)

ifneq (,$(filter install install-shim,$(MAKECMDGOALS)))
lib_path  := $(BLUELAB)/lib/$(firstword $(SUPPORTED_EXECUTION_MODES) vm)
have_libs := $(patsubst $(lib_path)/lib%.a,%,$(wildcard $(lib_path)/lib*.a))
real_libs := $(filter-out c,$(filter-out $(addsuffix _%,$(have_libs)),$(have_libs)))
miss_libs := $(filter-out $(dirs),$(real_libs))

ifneq (,$(miss_libs))
$(warning This build will not update the following libraries:)
$(foreach x,$(miss_libs),$(warning !!! $(x)))
$(warning Are you sure that's what you wanted?)
endif
endif
