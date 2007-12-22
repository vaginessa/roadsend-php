#
# Roadsend PHP Compiler
#
# First, make sure you have a Makefile.config in place. This should be a symlink to
# one of the Makefile.<platform> files.
#
# important targets:
#
# all        	- build support libraries, runtime, extensions, web backends and compiler
# unsafe     	- same as "all", but build "unsafe" (production) version
#              	  the production version is called "unsafe" for historical bigloo
#              	  reasons
# install	- install libraries and binaries
# clean      	- clean entire devel tree
#
# runtime    	- build the runtime libraries (including extensions)
# web-backends	  build web backends (microserver, fastcgi)
# tags       	- generate tags files for extensions
#
# dotest     	- build "dotest" regression testing program
# test		- run the stand alone test suite
# check      	- run main test suite, using dotest program (compares against Zend PHP)
# check5     	- run PHP5 specific test suite (compares against Zend PHP)
# check-all  	- run main test suite, and all extension test suites
#
#
PCC_ROOT = .
include bigloo-rules.mk

PWD 	= `pwd`
VERBOSE =
BIGLOO 	= bigloo 

prefix  	= /usr/local
exec_prefix 	= ${prefix}
bindir  	= ${exec_prefix}/bin
libdir		= ${exec_prefix}/lib
sysconfdir	= ${prefix}/etc

all: Makefile.config libs libs/libwebserver.$(SOEXT) profiler runtime webconnect \
     compiler extensions web-backends debugger shortpath dotest 

Makefile.config:
	touch $(PCC_ROOT)/Makefile.config

unsafe: 
	UNSAFE=t $(MAKE) all

tags: unsafe
	cd runtime && $(MAKE) tags

libs/libwebserver.$(SOEXT):
	(cd tools/libwebserver && \
         ./configure && \
         $(MAKE) all && \
         $(MAKE) install)

shortpath:
	(cd tools/shortpath && $(MAKE) shortpath)

#runtime
runtime: 
	(cd runtime && $(MAKE) runtime-libs)
.PHONY: runtime

#extensions
extensions: 
	(cd runtime && $(MAKE) extensions)

#compiler
compiler: webconnect
	(cd compiler && $(MAKE) all)
.PHONY: compiler

#debugger
debugger: web-backends
	(cd compiler && $(MAKE) debugger)
.PHONY: debugger

#webconnect
webconnect: 
	(cd webconnect && $(MAKE) all)
.PHONY: webconnect

#web backends
web-backends: webconnect compiler runtime
	(cd webconnect && $(MAKE) web-backends)

#profiler
profiler: libs
	(cd tools/profiler && $(MAKE) all)

libs: 
	-mkdir libs
#	-mkdir libs/dlls

clean: 
	-rm -rf testoutput
	-rm -f *.c *.o *.so libs/*.so libs/*.dylib libs/*.heap libs/*.a libs/*.dll libs/*.init libs/*.sch libs/*.h
	(cd runtime && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
	(cd compiler && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
	(cd webconnect && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
	(cd bugs && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
#	(cd doc && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
	(cd tools/profiler && $(MAKE) clean && UNSAFE=t $(MAKE) clean)
	-(cd tools/libwebserver && $(MAKE) clean)
	-(cd sa-tests && $(MAKE) clean)

clean-all: Makefile.config clean
	-rm config.log config.status Makefile.config

dotest: dotest.scm 
	$(BIGLOO) -srfi $(PCC_OS) -copt -D$(PCC_OS) dotest.scm -o dotest $(DOTEST_LIBS)

test:
	-(cd sa-tests && $(MAKE) clean)
	(cd sa-tests && $(MAKE))

check: dotest #all
	-rm -rf testoutput
	-mkdir testoutput
	./dotest tests/ testoutput/

check5: dotest
	-rm -rf testoutput
	-mkdir testoutput
	PHP=$(PHP5) PCC_OPTS=-5 ./dotest tests5/ testoutput/

check-all: all check
	(cd runtime/ext && $(MAKE) check)

docs:
	(cd doc && $(MAKE))

install:
#config
	install -m 755 -d $(DESTDIR)/$(sysconfdir)
	install -m 644 -b ./doc/pcc.conf $(DESTDIR)/$(sysconfdir)/pcc.conf	
#binaries
	install -m 755 -d $(DESTDIR)/$(bindir)
	install -m 755 ./compiler/pcc $(DESTDIR)/$(bindir)/pcc
	install -m 755 ./compiler/pdb $(DESTDIR)/$(bindir)/pdb
	install -m 755 ./compiler/pcctags $(DESTDIR)/$(bindir)/pcctags
	-install -m 755 ./webconnect/fastcgi/pcc.fcgi $(DESTDIR)/$(bindir)/pcc.fcgi
#libraries
	install -m 755 -d $(DESTDIR)/$(libdir)
	install -m 644 ./libs/libwebserver.so $(DESTDIR)/$(libdir)
	install -m 644 ./libs/libwebserver.a $(DESTDIR)/$(libdir)
	install -m 644 ./libs/*_[su]*.so $(DESTDIR)/$(libdir)
	install -m 644 ./libs/*_[su]*.a $(DESTDIR)/$(libdir)
	install -m 644 ./libs/*.sch $(DESTDIR)/$(libdir)
	install -m 644 ./libs/*.h $(DESTDIR)/$(libdir)
	install -m 644 ./libs/*.heap $(DESTDIR)/$(libdir)
	-install -m 644 ./libs/*.init $(DESTDIR)/$(libdir)

# used by the self installing package maker
package-install: unsafe
	./install.sh $(INSTALL_ROOT) $(INSTALL_PREFIX)

package-install-runtime: unsafe
	./install-runtime.sh $(INSTALL_ROOT) $(INSTALL_PREFIX)

