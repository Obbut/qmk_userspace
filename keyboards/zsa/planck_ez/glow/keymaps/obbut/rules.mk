OS_DETECTION_ENABLE = yes
TRI_LAYER_ENABLE = yes

# Enable ZSA defaults module (defines LED_LEVEL, TOGGLE_LAYER_COLOR keycodes
# required by planck_ez.c). Normally enabled via keymap.json community_modules,
# but we use keymap.c so we enable it manually.
OPT_DEFS += -DCOMMUNITY_MODULE_DEFAULTS_ENABLE
VPATH += modules/zsa/defaults
POST_CONFIG_H += keyboards/zsa/common/keycode_aliases.h
