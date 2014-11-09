USING: locals prettyprint arrays sequences kernel shuffle combinators
math math.vectors 
game.worlds game.loop ui.gadgets.worlds ui.pixel-formats
literals accessors assocs
game.input game.input.scancodes ui.gestures
mahjong.drawing mahjong.game
;

IN: mahjong

CONSTANT: WINDOW-WIDTH     1024
CONSTANT: WINDOW-HEIGHT    768

CONSTANT: BG-COLOR         [ 0.3 0.24 0.13 0.0 ]
CONSTANT: RESOURCES-PATH   "vocab:mahjong/_resources/"

CONSTANT: FACE-OFFSET      { 0 8 }
CONSTANT: STONE-EXTENTS    { 64 75 }
CONSTANT: STONE-3D-OFFSET  { -6 -9 }


CONSTANT: SPRITES {
    T{ sprite-atlas f "stones_bg.png" 2 1 70 85 }
    T{ sprite-atlas f "stones_fg.png" 16 15 64 64 } }

:: stone-pos ( I J LAYER -- pos )
    { I J } STONE-EXTENTS v* 2 v/n
    STONE-3D-OFFSET LAYER v*n v+
    ;

:: draw-stone-by-pos ( STONE-ID BG-ID POS -- )
    BG-ID STONE-HIDDEN = not [
        0 SPRITES nth BG-ID POS draw-sprite
        1 SPRITES nth STONE-ID POS FACE-OFFSET v+ draw-sprite 
    ] when ;

: draw-stone ( stone -- )
    [ id>> ] [ bg-id>> ] [ ijlayer>> ] tri
    stone-pos draw-stone-by-pos ;
  
TUPLE: mahjong-world < game-world 
    { board initial: { } } 
    layouts stone-descr ;

M: mahjong-world begin-game-world
    SPRITES [ RESOURCES-PATH load-sprite-atlas ] each
    RESOURCES-PATH load-layouts >>layouts
    dup layouts>> "Turtle" of >>board
    dup layouts>> values [ set-layout-blockers ] each
    RESOURCES-PATH load-stone-descriptions >>stone-descr
    dup [ board>> ] [ stone-descr>> length ] bi init-layout-random  
    drop ;

: in-stone? ( loc stone -- t/f )
    ijlayer>> stone-pos
    dup STONE-EXTENTS v+
    pick [ v> vall? ] 2bi@ and ; 

:: mouse-click ( WORLD LOC -- )
    WORLD board>> dup 
    [ LOC swap [ nip bg-id>> STONE-HIDDEN = not ] [ in-stone? ] 2bi and ] 
    find-last drop select-stone ;
  
mahjong-world H{
  { T{ button-down f f 1 } [ dup hand-rel mouse-click ] }
} set-gestures
                     
M: mahjong-world draw-world*
    enable-blend no-mip-filter
    dup dim>> [ first ] [ second ] bi setup-matrices
    BG-COLOR call clear-screen
    board>> [ draw-stone ] each ;

GAME: mahjong {
    { world-class mahjong-world }
    { title "Mahjong Solitaire" }
    { pixel-format-attributes {
        windowed double-buffered T{ depth-bits { value 24 } } } }
    { pref-dim { $ WINDOW-WIDTH $ WINDOW-HEIGHT } }
    { tick-interval-nanos $[ 60 fps ] }
} ;

