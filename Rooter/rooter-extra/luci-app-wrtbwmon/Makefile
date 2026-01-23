#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wrtbwmon
PKG_VERSION:=4.500
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/luci-app-wrtbwmon
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+wrtbwmon
  TITLE:=A Luci module that uses wrtbwmon to track bandwidth usage
  PKGARCH:=all
endef

define Package/luci-app-wrtbwmon/description
  A Luci module that uses wrtbwmon to track bandwidth usage
endef


define Build/Compile
endef

define Package/luci-app-wrtbwmon/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-wrtbwmon))
