USING: kernel math accessors sequences arrays
math.vectors
splitting grouping hashtables sets hash-sets assocs locals
io.files io.encodings.ascii unicode.categories math.ranges math.order sorting.slots
random match ;
IN: mahjong.game

CONSTANT: DEFAULT-STONE-ID 4

CONSTANT: STONE-NORMAL     0
CONSTANT: STONE-SELECTED   1
CONSTANT: STONE-HIDDEN    -1

CONSTANT: BLOCK-OFFSETS    { { 0 0 } { 1 0 } { 0 1 } { 1 1 } }

CONSTANT: TOP-BLOCKING     { {  0 0 1 } {  0 1 1 } { 1 0 1 } { 1 1 1 } }
CONSTANT: LEFT-BLOCKING    { { -1 0 0 } { -1 1 0 } }
CONSTANT: RIGHT-BLOCKING   { {  2 0 0 } {  2 1 0 } } 

TUPLE: stone-blocking top left right ;
: <stone-blocking> ( -- stone-blocking ) { } { } { } stone-blocking boa ;
    
TUPLE: stone i j layer id { bg-id initial: 0 } blocking ;
: <stone> ( i j layer -- stone ) DEFAULT-STONE-ID STONE-NORMAL <stone-blocking> stone boa ;

: ijlayer>> ( stone -- i j layer ) [ i>> ] [ j>> ] [ layer>> ] tri ;

: hide-stones ( layout idx-seq -- )
    [ over nth STONE-HIDDEN >>bg-id ] map 2drop ;

: toggle-select ( stone -- )
    dup bg-id>> STONE-SELECTED = 
    [ STONE-NORMAL ] [ STONE-SELECTED ] if >>bg-id drop ;

: get-selected ( layout -- sel-idx )
    [ bg-id>> ] map STONE-SELECTED swap indices ;

:: is-blocked? ( STONE LAYOUT -- t/f )
    STONE blocking>> [ top>> ] [ left>> ] [ right>> ] tri 
    [ [ LAYOUT nth bg-id>> STONE-HIDDEN = not ] any? ] tri@ and or ;

: unselect-all ( layout -- )
    [ dup bg-id>> STONE-HIDDEN = not [ STONE-NORMAL >>bg-id  ] when drop ] each ;

MATCH-VARS: ?a ;
:: hide-match ( LAYOUT -- )
    LAYOUT get-selected dup 
    [ LAYOUT nth id>> ] map { ?a ?a } match
    [ LAYOUT swap hide-stones ] [ drop ] if ;

:: select-stone ( LAYOUT STONE-IDX/F -- )
    STONE-IDX/F [ 
        LAYOUT nth 
        dup LAYOUT is-blocked? [ drop ] [ toggle-select ] if 
    ] [
        LAYOUT unselect-all
    ] if* 
    LAYOUT hide-match ;

<PRIVATE

:: set-at ( pos val pos-arr -- )
    val pos second
    pos first pos-arr nth
    set-nth ;

:: dec-block ( pos-arr i j layer --  )
    BLOCK-OFFSETS [ { j i } v+ layer -1 + pos-arr set-at ] each ;

:: peel-block ( VAL I J POS-ARR LAYER -- layout-entry/f )
    BLOCK-OFFSETS [ { J I } v+ POS-ARR [ swap ?nth ] reduce ] map
    [ LAYER = ] all?
    [ POS-ARR I J LAYER [ dec-block ] 3keep <stone> ] [ f ] if ;

:: peel-layer ( LAYER POS-ARR -- layout-entries )
    POS-ARR but-last [
        swap but-last [
            pick POS-ARR LAYER peel-block
        ] map-index sift nip
    ] map-index concat ;

PRIVATE>

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

:: get-blocking ( BLOCKERS COV POS -- blocking )
    BLOCKERS [ POS v+ COV swap of ] map sift >hash-set members ;

:: get-tlr-blocking ( COV POS -- blocking )
    TOP-BLOCKING LEFT-BLOCKING RIGHT-BLOCKING
    [ COV POS get-blocking ] tri@ stone-blocking boa ;

: build-layout-blockers ( layout -- blocking-arr )
    [ coverage-table ] keep
    [ ijlayer>> 3array 2dup get-tlr-blocking nip ] map nip ;

: set-layout-blockers ( layout -- )
    [ build-layout-blockers ] keep [ swap >>blocking drop ] 2each ;

: load-layouts ( res-path -- layouts )
    "layouts.txt" append ascii file-lines 
    [ "---" swap start ] split-when harvest 2 group
    [ dup first first [ blank? ] trim
      swap second parse-layout 2array ] map >hashtable ;

: load-stone-descriptions ( res-path -- descr-array )
    "stones_desc.txt" append ascii file-lines 
    [ "|" split ] map [ length 2 = ] filter ;

: init-layout-random ( layout num-stone-types -- )
    iota over length 4 / sample 
    4 [ dup ] replicate concat nip
    [ >>id drop ] 2each ;
