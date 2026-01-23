#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=basic-zerotier
PKG_VERSION:=4.500
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/basic-zerotier
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+zerotier +extramenu
  TITLE:=Install scripts for Basic Zerotier
  PKGARCH:=all
endef

define Package/basic-zerotier/description
  Install scripts for Basic Zerotier
endef


define Build/Compile
endef

define Package/basic-zerotier/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,basic-zerotier))
