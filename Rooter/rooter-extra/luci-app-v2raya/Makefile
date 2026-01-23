#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-v2raya
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/luci-app-v2raya
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+v2raya
  TITLE:=LuCI support for v2raya
  PKGARCH:=all
endef

define Package/luci-app-v2raya/description
  Helper scripts to install LuCI support for v2raya
endef


define Build/Compile
endef

define Package/luci-app-v2raya/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,luci-app-v2raya))
