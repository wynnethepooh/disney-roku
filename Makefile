APPNAME = disney_roku
ZIP_EXCLUDE= -x keys\* -x store_assets\*
APPSROOT = ../..

GL_IS_DELETE_SGDEX_FOLDERS=true

include $(APPSROOT)/app.mk
