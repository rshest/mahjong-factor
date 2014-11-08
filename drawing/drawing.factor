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

:: setup-matrices ( width height -- )
    GL_PROJECTION glMatrixMode glLoadIdentity
    0.0 width >float height >float 0.0 gluOrtho2D
    GL_MODELVIEW glMatrixMode glLoadIdentity ;

: clear-screen ( r g b a -- )
    glClearColor
    GL_COLOR_BUFFER_BIT glClear ;

: get-uv-scale ( frame-side dim -- scale )
    [ GL_TEXTURE_2D 0 ] dip get-texture-int [ >float ] bi@ / ;

:: load-sprite-atlas ( atlas res-path --  )
    res-path atlas file-path>> append load-image
    make-texture atlas swap >>texture-id 
    GL_TEXTURE_2D atlas texture-id>> glBindTexture
    atlas frame-width>> GL_TEXTURE_WIDTH get-uv-scale >>s-scale
    atlas frame-height>> GL_TEXTURE_HEIGHT get-uv-scale >>t-scale drop ;

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
