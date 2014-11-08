USING: tools.test mahjong.game accessors
kernel math math.order sorting sequences assocs namespaces arrays ;

IN: mahjong.game.tests

CONSTANT: TEST-LAYOUT { "123321 "
                        "123321" }
SYMBOL: LAYOUT
TEST-LAYOUT parse-layout LAYOUT set 
                        
[ 6 ] [ LAYOUT get length ] unit-test

[ t ] [ LAYOUT get [ ijlayer>> 3array ] map
        { { 0 0 1 } { 2 0 1 } { 4 0 1 } { 1 0 2 } { 3 0 2 } { 2 0 3 } } =
      ] unit-test

: sorted-by-accessor? ( layout quot -- t/f ) map dup [ <=> ] sort = ; inline
[ t ] [ LAYOUT get [ layer>> ] sorted-by-accessor? ] unit-test

SYMBOL: LAYOUT-COVERAGE
LAYOUT get coverage-table LAYOUT-COVERAGE set

[ 24 ] [ LAYOUT-COVERAGE get >alist length ] unit-test
