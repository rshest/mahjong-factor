USING: tools.test mahjong
sequences ;

IN: mahjong.tests

CONSTANT: TEST-LAYOUT { "123321 "
                        "123321" }

[ 6 ] [ TEST-LAYOUT parse-layout length ] unit-test