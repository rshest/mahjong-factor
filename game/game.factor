USING: kernel math accessors sequences arrays
math.vectors
splitting grouping hashtables sets hash-sets assocs locals
io.files io.encodings.ascii unicode.categories math.ranges math.order sorting.slots
;
IN: mahjong.game

CONSTANT: DEFAULT-STONE-ID 4

CONSTANT: STONE-NORMAL     0
CONSTANT: STONE-SELECTED   1
CONSTANT: STONE-REMOVED    -1

CONSTANT: BLOCK-OFFSETS    { { 0 0 } { 1 0 } { 0 1 } { 1 1 } }

CONSTANT: TOP-BLOCKING     { {  0 0 1 } {  0 1 1 } { 1 0 1 } { 1 1 1 } }
CONSTANT: LEFT-BLOCKING    { { -1 0 0 } { -1 1 0 } }
CONSTANT: RIGHT-BLOCKING   { {  2 0 0 } {  2 1 0 } } 

TUPLE: stone-blocking top left right ;
: <stone-blocking> ( -- stone-blocking ) { } { } { } stone-blocking boa ;
    
TUPLE: stone i j layer id { bg-id initial: 0 } blocking ;
: <stone> ( i j layer -- stone ) DEFAULT-STONE-ID STONE-NORMAL <stone-blocking> stone boa ;

: ijlayer>> ( stone -- i j layer ) [ i>> ] [ j>> ] [ layer>> ] tri ;

:: set-at ( pos val pos-arr -- )
    val pos second
    pos first pos-arr nth
    set-nth ;

:: dec-block ( pos-arr i j layer --  )
    BLOCK-OFFSETS [ { j i } v+ layer -1 + pos-arr set-at ] each ;

:: peel-block ( val i j pos-arr layer -- layout-entry/f )
    BLOCK-OFFSETS [ { j i } v+ pos-arr [ swap ?nth ] reduce ] map
    [ layer = ] all?
    [ pos-arr i j layer [ dec-block ] 3keep <stone> ] [ f ] if ;

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

: coverage-table ( layout -- table )
    [ [let :> idx ijlayer>> :> layer :> j :> i
        BLOCK-OFFSETS [ { i j } v+ { layer } append idx 2array ] map
    ] ] map-index concat >hashtable ;

:: get-blocking ( blockers cov pos -- blocking )
    blockers [ pos v+ cov swap of ] map sift >hash-set members ;

:: get-tlr-blocking ( cov pos -- blocking )
    TOP-BLOCKING LEFT-BLOCKING RIGHT-BLOCKING
    [ cov pos get-blocking ] tri@ stone-blocking boa ;

: build-layout-blockers ( layout -- blocking-arr )
    [ coverage-table ] keep
    [ ijlayer>> 3array 2dup get-tlr-blocking nip ] map nip ;

: is-free? ( stone board -- t/f )
    2drop f ;

: load-layouts ( res-path -- layouts )
    "layouts.txt" append ascii file-lines 
    [ "---" swap start ] split-when harvest 2 group
    [ dup first first [ blank? ] trim
      swap second parse-layout 2array ] map >hashtable ;
