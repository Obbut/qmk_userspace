.PHONY: all left right clean flash-left flash-right draw

KEYBOARD = splitkb/halcyon/kyria/rev4
KEYMAP = obbut

all: left right

left:
	qmk compile -kb $(KEYBOARD) -km $(KEYMAP) -e HLC_CIRQUE_TRACKPAD=1 -e TARGET=kyria_rev4_obbut_cirque

right:
	qmk compile -kb $(KEYBOARD) -km $(KEYMAP) -e HLC_ENCODER=1 -e TARGET=kyria_rev4_obbut_encoder

flash-left:
	qmk flash -kb $(KEYBOARD) -km $(KEYMAP) -e HLC_CIRQUE_TRACKPAD=1 -e TARGET=kyria_rev4_obbut_cirque

flash-right:
	qmk flash -kb $(KEYBOARD) -km $(KEYMAP) -e HLC_ENCODER=1 -e TARGET=kyria_rev4_obbut_encoder

clean:
	rm -f *.uf2 *.hex *.bin

draw:
	./draw-keymap.sh
