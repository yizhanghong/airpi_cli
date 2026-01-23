#Owned by DairyMan@Whirlpool
# 
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-mhi
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk
#  +kmod-mhi-pci-generic
define Package/ext-mhi
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+kmod-mhi-bus +kmod-mhi-net +kmod-mhi-pci-generic +kmod-mhi-wwan-ctrl \
		+kmod-mhi-wwan-mbim +qmi-utils +pciutils +kmod-mtk-t7xx +mbim-utils \
		+kmod-mhi-pci-generic +kmod-qrtr-mhi
  TITLE:=support for MHI
  PKGARCH:=all
endef

define Package/ext-mhi/description
  Helper scripts to enable MHI
endef


define Build/Compile
endef

define Package/ext-mhi/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ext-mhi))
