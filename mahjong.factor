USING: locals prettyprint arrays sequences kernel shuffle combinators
math math.vectors
opengl opengl.gl opengl.glu opengl.demo-support opengl.textures
game.worlds game.loop ui.gadgets.worlds ui.pixel-formats
literals accessors images.loader ;
IN: mahjong

CONSTANT: width 1024
CONSTANT: height 768

CONSTANT: bg-color        [ 0.3 0.24 0.13 0.0 ]
CONSTANT: resources-path  "vocab:mahjong/"

CONSTANT: face-offset     { 0 8 }
CONSTANT: stone-extents   { 65 77 }
CONSTANT: stone-3d-offset { -7 -10 }

TUPLE: sprite-atlas
    file-path cols rows frame-width frame-height
    { texture-id initial: 0 } s-scale t-scale ;

: enable-blend ( -- ) 
    GL_BLEND glEnable
    GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA glBlendFunc ;

: no-mip-filter ( -- )
    GL_TEXTURE_2D glEnable
    GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri ;

: setup-matrices ( -- )
    GL_PROJECTION glMatrixMode glLoadIdentity
    0.0 width >float height >float 0.0 gluOrtho2D
    GL_MODELVIEW glMatrixMode glLoadIdentity ;

: clear-screen ( -- )
    bg-color call glClearColor
    GL_COLOR_BUFFER_BIT glClear ;

: get-uv-scale ( frame-side dim -- scale )
    [ GL_TEXTURE_2D 0 ] dip get-texture-int [ >float ] bi@ / ;

: load-sprite-atlas ( sprite-atlas --  )
    dup file-path>> resources-path swap append load-image
    make-texture [ >>texture-id ] keep
    GL_TEXTURE_2D swap glBindTexture
    dup frame-width>> GL_TEXTURE_WIDTH get-uv-scale >>s-scale
    dup frame-height>> GL_TEXTURE_HEIGHT get-uv-scale >>t-scale drop ;

CONSTANT: sprite-atlases {
    T{ sprite-atlas f "stones_bg.png" 2 1 70 85 }
    T{ sprite-atlas f "stones_fg.png" 16 15 64 64 } }

:: draw-sprite ( atlas-id sprite-id pos -- )
    atlas-id sprite-atlases nth
    dup texture-id>> GL_TEXTURE_2D swap glBindTexture ! set the atlas texture as current   
    no-mip-filter
    [let pos first  :> x
         pos second :> y
         dup frame-width>>  x + :> r
         dup frame-height>> y + :> b
         dup cols>> sprite-id swap /mod [ >float ] bi@ :> col :> row
         dup s-scale>> col * :> u
         dup t-scale>> row * :> v
         dup s-scale>> u + :> u1
         dup t-scale>> v + :> v1
        GL_QUADS [
            u  v  glTexCoord2f x y glVertex2f
            u1 v  glTexCoord2f r y glVertex2f
            u1 v1 glTexCoord2f r b glVertex2f
            u  v1 glTexCoord2f x b glVertex2f
        ] do-state ] drop ;

:: stone-pos ( i j layer -- pos )
    { i j } stone-extents v* 2 v/n
    stone-3d-offset layer v*n v+
    ;

TUPLE: stone i j layer id { bg-id initial: 0 } ;
    
:: draw-stone-by-pos ( stone-id bg-id pos -- )
    0 bg-id pos draw-sprite
    1 stone-id pos face-offset v+ draw-sprite ;

: draw-stone ( stone -- )
    { [ id>> ] [ bg-id>> ] [ i>> ] [ j>> ] [ layer>> ] } cleave
    stone-pos draw-stone-by-pos ;
    
TUPLE: mahjong-world < game-world 
    { board initial: { } } ;

M: mahjong-world begin-game-world
    sprite-atlases [ load-sprite-atlas ] each
    150 iota [ [let :> idx
        idx 15 /mod [ 2 * ] bi@ swap
        0 idx 0  stone boa ] ] map >>board
    drop
    ;

M: mahjong-world draw-world*
    enable-blend no-mip-filter setup-matrices clear-screen
    board>> [ draw-stone ] each ;

GAME: mahjong {
    { world-class mahjong-world }
    { title "Factor Mahjong" }
    { pixel-format-attributes {
        windowed double-buffered T{ depth-bits { value 24 } } } }
    { pref-dim { $ width $ height } }
    { tick-interval-nanos $[ 60 fps ] }
} ;

