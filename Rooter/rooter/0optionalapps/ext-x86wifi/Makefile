#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-x86wifi
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-x86wifi
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+kmod-ath10k +kmod-ath11k +kmod-ath11k-pci +kmod-ath9k \
	+kmod-mt76 +kmod-mt76-connac +kmod-mt76-core +kmod-mt7601u +kmod-mt7603 \
	+kmod-mt7615e +kmod-mt7663s +kmod-mt7663u +kmod-mt76x0e +kmod-mt76x0u \
	+kmod-mt76x2 +kmod-mt76x2u +kmod-mt7915e +kmod-mt7921e +kmod-mt7921s +kmod-mt7921u \
	+kmod-mt7925e +kmod-mt7925u +kmod-mt7996e +kmod-mt7615-firmware \
	+kmod-mt7622-firmware +kmod-mt7663-firmware-ap +kmod-mt7663-firmware-sta \
	+kmod-mt7915-firmware +kmod-mt7916-firmware +kmod-mt7921-firmware \
	+kmod-mt7922-firmware +kmod-mt7996-firmware +mt7601u-firmware +mt7622bt-firmware \
	+mt7921bt-firmware +mt7922bt-firmware +mt7988-2p5g-phy-firmware \
	+ath10k-board-qca4019 +ath10k-board-qca9377 \
	+ath10k-board-qca9887 +ath10k-board-qca9888 +ath10k-board-qca988x \
	+ath10k-board-qca9984 +ath10k-board-qca99x0 \
	+ath10k-firmware-qca4019 +ath10k-firmware-qca6174 \
	+ath10k-firmware-qca9377 +ath10k-firmware-qca9887 +ath10k-firmware-qca9888 \
	+ath10k-firmware-qca988x +ath10k-firmware-qca9984 +ath10k-firmware-qca99x0-ct \
	+ath11k-firmware-ipq8074 +ath11k-firmware-qca6390 +ath11k-firmware-qcn9074 \
	+ath11k-firmware-wcn6750 +ath11k-firmware-wcn6855
  TITLE:=support for wifi on x86
  PKGARCH:=all
endef

define Package/ext-x86wifi/description
  Helper scripts to enable wifi on x86
endef


define Build/Compile
endef


$(eval $(call BuildPackage,ext-x86wifi))
