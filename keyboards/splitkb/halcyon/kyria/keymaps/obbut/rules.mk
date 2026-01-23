ENCODER_MAP_ENABLE = yes
OS_DETECTION_ENABLE = yes

# This adds module functionality to your keyboard (files found in users/halcyon_modules)
USER_NAME := halcyon_modules

# Include shared obbut code (Swift + C glue layer)
VPATH += $(QMK_USERSPACE)/users/obbut_halcyon
include $(QMK_USERSPACE)/users/obbut_halcyon/rules.mk
