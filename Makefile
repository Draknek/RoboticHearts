OUTPUT := hearts.swf

ifdef DEBUG
DEBUG_FLAG := true
else
DEBUG_FLAG := false
endif

all:
	cd levels && python build.py
	fcsh-wrap -optimize=true -output $(OUTPUT) -static-link-runtime-shared-libraries=true -compatibility-version=3.0.0 --target-player=10.0.0 -compiler.debug=$(DEBUG_FLAG) Preloader.as -frames.frame mainframe Main
	fcsh-wrap -optimize=true -output update-db.swf -static-link-runtime-shared-libraries=true -compatibility-version=3.0.0 --target-player=10.0.0 -compiler.debug=true UpdateDB.as


clean:
	rm -f *~ $(OUTPUT) .FW.*

.PHONY: all clean


