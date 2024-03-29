USING: locals prettyprint arrays sequences kernel shuffle combinators
math math.vectors 
game.worlds game.loop ui.gadgets.worlds ui.pixel-formats
literals accessors assocs
game.input game.input.scancodes ui.gestures
ui.gadgets.status-bar
mahjong.drawing mahjong.game
random
;

IN: mahjong

CONSTANT: WINDOW-WIDTH     700
CONSTANT: WINDOW-HEIGHT    500

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
    layouts 
    stone-descr 
    { board-offset initial: { 20.0 50.0 } } 
    { board-scale initial: 0.7 } 
    ;

: new-game ( world -- )
    dup layouts>> dup keys 1 sample first of >>board    
    dup [ board>> ] [ stone-descr>> length ] bi init-layout-random  
    drop ;

M: mahjong-world begin-game-world
    SPRITES [ RESOURCES-PATH load-sprite-atlas ] each
    RESOURCES-PATH load-layouts >>layouts
    RESOURCES-PATH load-stone-descriptions >>stone-descr
    dup new-game
    drop ;

: in-stone? ( loc stone -- t/f )
    ijlayer>> stone-pos
    dup STONE-EXTENTS v+
    pick [ v> vall? ] 2bi@ and ; 

:: mouse-click ( WORLD LOC -- )
    [let LOC WORLD board-offset>> v- WORLD board-scale>> v/n :> LOC1
        WORLD board>> dup 
        [ LOC1 swap [ nip bg-id>> STONE-HIDDEN = not ] [ in-stone? ] 2bi and ] 
        find-last drop select-stone ] ;
  
mahjong-world H{
  { T{ button-down f f 1 } [ dup hand-rel mouse-click ] }
} set-gestures
                     
M: mahjong-world draw-world*
    enable-blend no-mip-filter 
    dup [ board-offset>> ] [  board-scale>> ] [ dim>> ] tri
    [ first ] [ second ] bi setup-matrices
    BG-COLOR call clear-screen
    board>> [ draw-stone ] each ;

GAME: mahjong {
    { world-class mahjong-world }
    { title "Mahjong Solitaire" }
    { pixel-format-attributes {
        windowed double-buffered T{ depth-bits { value 24 } } } }
    { pref-dim { $ WINDOW-WIDTH $ WINDOW-HEIGHT } }
    { tick-interval-nanos $[ 60 fps ] } } ;

