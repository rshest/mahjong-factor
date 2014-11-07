USING: locals prettyprint arrays sequences kernel shuffle combinators
math math.vectors
opengl opengl.gl opengl.glu opengl.demo-support opengl.textures
game.worlds game.loop ui.gadgets.worlds ui.pixel-formats
literals accessors images.loader
splitting grouping hashtables assocs
io.files io.encodings.ascii unicode.categories math.ranges math.order sorting.slots
game.input game.input.scancodes ui.gestures
;

IN: mahjong

CONSTANT: WINDOW-WIDTH     1024
CONSTANT: WINDOW-HEIGHT    768

CONSTANT: BG-COLOR         [ 0.3 0.24 0.13 0.0 ]
CONSTANT: RESOURCES-PATH   "vocab:mahjong/"

CONSTANT: FACE-OFFSET      { 0 8 }
CONSTANT: STONE-EXTENTS    { 64 75 }
CONSTANT: STONE-3D-OFFSET  { -6 -9 }
CONSTANT: DEFAULT-STONE-ID 4
CONSTANT: STONE-NORMAL     0
CONSTANT: STONE-SELECTED   1

CONSTANT: BLOCK-OFFSETS    { { 0 0 } { 1 0 } { 0 1 } { 1 1 } }

CONSTANT: TOP-BLOCKING     { { 0 0 1 } { 0 1 1 } { 1 0 1 } { 1 1 1 } }
CONSTANT: LEFT-BLOCKING    { { -1 0 0 } { -1 1 0 } }
CONSTANT: RIGHT-BLOCKING   { { 2 0 0 } { 2 1 0 } }

TUPLE: sprite-atlas
    file-path cols rows frame-width frame-height
    { texture-id initial: 0 } s-scale t-scale ;

TUPLE: stone i j layer id { bg-id initial: 0 } ;
TUPLE: stone-blocking top left right ;

CONSTANT: SPRITES {
    T{ sprite-atlas f "stones_bg.png" 2 1 70 85 }
    T{ sprite-atlas f "stones_fg.png" 16 15 64 64 } }


: enable-blend ( -- ) 
    GL_BLEND glEnable
    GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA glBlendFunc ;

: no-mip-filter ( -- )
    GL_TEXTURE_2D glEnable
    GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri ;

: setup-matrices ( -- )
    GL_PROJECTION glMatrixMode glLoadIdentity
    0.0 WINDOW-WIDTH >float WINDOW-HEIGHT >float 0.0 gluOrtho2D
    GL_MODELVIEW glMatrixMode glLoadIdentity ;

: clear-screen ( -- )
    BG-COLOR call glClearColor
    GL_COLOR_BUFFER_BIT glClear ;

: get-uv-scale ( frame-side dim -- scale )
    [ GL_TEXTURE_2D 0 ] dip get-texture-int [ >float ] bi@ / ;

: load-sprite-atlas ( sprite-atlas --  )
    dup file-path>> RESOURCES-PATH swap append load-image
    make-texture [ >>texture-id ] keep
    GL_TEXTURE_2D swap glBindTexture
    dup frame-width>> GL_TEXTURE_WIDTH get-uv-scale >>s-scale
    dup frame-height>> GL_TEXTURE_HEIGHT get-uv-scale >>t-scale drop ;

:: draw-sprite ( atlas sprite-id pos -- )
    GL_TEXTURE_2D atlas texture-id>> glBindTexture    
    no-mip-filter
    [let pos first  :> x
         pos second :> y
         atlas frame-width>>  x + :> r
         atlas frame-height>> y + :> b
         atlas cols>> sprite-id swap /mod [ >float ] bi@ :> col :> row
         atlas s-scale>> col * :> u
         atlas t-scale>> row * :> v
         atlas s-scale>> u + :> u1
         atlas t-scale>> v + :> v1
        GL_QUADS [
            u  v  glTexCoord2f x y glVertex2f
            u1 v  glTexCoord2f r y glVertex2f
            u1 v1 glTexCoord2f r b glVertex2f
            u  v1 glTexCoord2f x b glVertex2f
        ] do-state ] ;

:: stone-pos ( i j layer -- pos )
    { i j } STONE-EXTENTS v* 2 v/n
    STONE-3D-OFFSET layer v*n v+
    ;

:: draw-stone-by-pos ( stone-id bg-id pos -- )
    0 SPRITES nth bg-id pos draw-sprite
    1 SPRITES nth stone-id pos FACE-OFFSET v+ draw-sprite ;

: draw-stone ( stone -- )
    { [ id>> ] [ bg-id>> ] [ i>> ] [ j>> ] [ layer>> ] } cleave
    stone-pos draw-stone-by-pos ;

:: set-at ( pos val pos-arr -- )
    val pos second
    pos first pos-arr nth
    set-nth ;

:: dec-block ( pos-arr i j layer --  )
    BLOCK-OFFSETS [ { j i } v+ layer -1 + pos-arr set-at ] each ;

:: peel-block ( val i j pos-arr layer -- layout-entry/f )
    BLOCK-OFFSETS [ { j i } v+ pos-arr [ swap ?nth ] reduce ] map
    [ layer = ] all?
    [ pos-arr i j layer [ dec-block ] 3keep
      DEFAULT-STONE-ID STONE-NORMAL stone boa ] [ f ] if ;

:: peel-layer ( layer pos-arr -- layout-entries )
    pos-arr but-last [
        swap but-last [
            pick pos-arr layer peel-block
        ] map-index sift nip
    ] map-index concat ;

: parse-layout ( lines -- layout )
    [ >array [ 48 - ] map ] map
    [let :> pos-arr
        pos-arr supremum supremum :> max-layer
        max-layer 1 [a,b] [ pos-arr peel-layer ] map concat ]
    { { layer>> <=> } { i>> <=> } { j>> <=> }  } sort-by ;

: load-layouts ( -- layouts )
    RESOURCES-PATH "layouts.txt" append ascii file-lines 
    [ "---" swap start ] split-when harvest 2 group
    [ dup first first [ blank? ] trim
      swap second parse-layout 2array ] map >hashtable ;

: coverage-table ( layout -- table )
    [ [let :> idx [ i>> ] [ j>> ] [ layer>> ] tri :> i :> j :> layer
        BLOCK-OFFSETS [ { i j } v+ { layer } append idx 2array ] map
    ] ] map-index concat >hashtable ;

: get-blocking-neighbors ( layout -- blocking-arr )
    
    ;
  
TUPLE: mahjong-world < game-world 
    { board initial: { } } layouts ;

M: mahjong-world begin-game-world
    SPRITES [ load-sprite-atlas ] each
    load-layouts >>layouts
    dup layouts>> "Turtle" of >>board
    drop ;

: in-stone? ( loc stone -- t/f )
  { [ i>> ] [ j>> ] [ layer>> ] } cleave stone-pos
    dup STONE-EXTENTS v+
    pick [ v> vall? ] 2bi@ and ;
  
:: mouse-click ( world loc -- )
  world board>> [ loc swap in-stone? ] find-last
  [ world board>> nth 1 >>bg-id ] when drop ;
  
mahjong-world H{
  { T{ button-down f f 1 } [ dup hand-rel mouse-click ] }
} set-gestures
                     
M: mahjong-world draw-world*
    enable-blend no-mip-filter setup-matrices clear-screen
    board>> [ draw-stone ] each ;

GAME: mahjong {
    { world-class mahjong-world }
    { title "Factor Mahjong" }
    { pixel-format-attributes {
        windowed double-buffered T{ depth-bits { value 24 } } } }
    { pref-dim { $ WINDOW-WIDTH $ WINDOW-HEIGHT } }
    { tick-interval-nanos $[ 60 fps ] }
} ;

