USING: kernel locals math accessors sequences
opengl opengl.gl opengl.glu opengl.demo-support opengl.textures
images.loader ;

IN: mahjong.drawing

TUPLE: sprite-atlas
    file-path cols rows frame-width frame-height
    { texture-id initial: 0 } s-scale t-scale ;

: enable-blend ( -- ) 
    GL_BLEND glEnable
    GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA glBlendFunc ;

: no-mip-filter ( -- )
    GL_TEXTURE_2D glEnable
    GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR glTexParameteri ;

:: setup-matrices ( OFFSET SCALE WIDTH HEIGHT -- )
    GL_PROJECTION glMatrixMode glLoadIdentity
    0.0 WIDTH >float HEIGHT >float 0.0 gluOrtho2D
    GL_MODELVIEW glMatrixMode 
    glLoadIdentity 
    OFFSET first OFFSET second 0.0 glTranslatef
    SCALE SCALE SCALE glScalef ;

: clear-screen ( r g b a -- )
    glClearColor
    GL_COLOR_BUFFER_BIT glClear ;

: get-uv-scale ( frame-side dim -- scale )
    [ GL_TEXTURE_2D 0 ] dip get-texture-int [ >float ] bi@ / ;

:: load-sprite-atlas ( ATLAS RES-PATH --  )
    RES-PATH ATLAS file-path>> append load-image
    make-texture ATLAS swap >>texture-id 
    GL_TEXTURE_2D ATLAS texture-id>> glBindTexture
    ATLAS frame-width>> GL_TEXTURE_WIDTH get-uv-scale >>s-scale
    ATLAS frame-height>> GL_TEXTURE_HEIGHT get-uv-scale >>t-scale drop ;

:: draw-sprite ( ATLAS SPRITE-ID POS -- )
    GL_TEXTURE_2D ATLAS texture-id>> glBindTexture    
    no-mip-filter
    [let POS first  :> x
         POS second :> y
         ATLAS frame-width>>  x + :> r
         ATLAS frame-height>> y + :> b
         ATLAS cols>> SPRITE-ID swap /mod [ >float ] bi@ :> col :> row
         ATLAS s-scale>> col * :> u
         ATLAS t-scale>> row * :> v
         ATLAS s-scale>> u + :> u1
         ATLAS t-scale>> v + :> v1
        GL_QUADS [
            u  v  glTexCoord2f x y glVertex2f
            u1 v  glTexCoord2f r y glVertex2f
            u1 v1 glTexCoord2f r b glVertex2f
            u  v1 glTexCoord2f x b glVertex2f
        ] do-state ] ;
