;==============================================================================
; levels.asm
;
; Platform and bomb coordinate tables for the milestone 8 handcrafted level pass.
; Each platform row stores row,start,length. Each bomb row stores column,row.
;==============================================================================

LevelPlatformTable:
        fdb     Level1Platforms
        fdb     Level2Platforms
        fdb     Level3Platforms
        fdb     Level4Platforms
        fdb     Level5Platforms
        fdb     Level6Platforms
        fdb     Level7Platforms
        fdb     Level8Platforms
        fdb     Level9Platforms
        fdb     Level10Platforms

LevelBombTable:
        fdb     Level1BombPositions
        fdb     Level2BombPositions
        fdb     Level3BombPositions
        fdb     Level4BombPositions
        fdb     Level5BombPositions
        fdb     Level6BombPositions
        fdb     Level7BombPositions
        fdb     Level8BombPositions
        fdb     Level9BombPositions
        fdb     Level10BombPositions

Level1Platforms:
        fcb     19,4,6
        fcb     20,19,10
        fcb     16,15,7
        fcb     10,7,6
        fcb     7,18,9

Level2Platforms:
        fcb     18,4,7
        fcb     20,19,10
        fcb     14,5,8
        fcb     11,16,9
        fcb     7,22,6

Level3Platforms:
        fcb     21,18,8
        fcb     20,18,6
        fcb     15,4,5
        fcb     11,20,8
        fcb     7,8,7

Level4Platforms:
        fcb     21,5,7
        fcb     20,19,10
        fcb     16,16,8
        fcb     11,6,7
        fcb     6,21,7

Level5Platforms:
        fcb     20,13,6
        fcb     19,22,7
        fcb     14,14,7
        fcb     9,18,8
        fcb     6,22,7

Level6Platforms:
        fcb     21,23,6
        fcb     20,18,7
        fcb     15,5,8
        fcb     12,20,7
        fcb     8,17,6

Level7Platforms:
        fcb     20,5,8
        fcb     20,19,10
        fcb     16,18,8
        fcb     12,4,8
        fcb     7,17,8

Level8Platforms:
        fcb     20,3,7
        fcb     19,19,10
        fcb     14,12,7
        fcb     10,4,8
        fcb     8,19,8

Level9Platforms:
        fcb     21,12,7
        fcb     19,18,10
        fcb     15,5,7
        fcb     11,18,7
        fcb     7,10,7

Level10Platforms:
        fcb     20,5,7
        fcb     19,19,10
        fcb     15,13,7
        fcb     11,3,8
        fcb     7,21,7

Level1BombPositions:
        fcb     5,2
        fcb     9,2
        fcb     13,2
        fcb     23,2
        fcb     27,2
        fcb     29,2
        fcb     15,8
        fcb     19,8
        fcb     23,8
        fcb     27,8
        fcb     1,11
        fcb     1,14
        fcb     1,17
        fcb     1,20
        fcb     29,11
        fcb     29,14
        fcb     29,17
        fcb     29,20

Level2BombPositions:
        fcb     3,3
        fcb     7,3
        fcb     11,3
        fcb     15,5
        fcb     19,5
        fcb     23,5
        fcb     27,5
        fcb     24,9
        fcb     20,9
        fcb     16,9
        fcb     12,12
        fcb     8,12
        fcb     4,12
        fcb     6,16
        fcb     10,16
        fcb     14,20
        fcb     22,21
        fcb     27,21

Level3BombPositions:
        fcb     2,4
        fcb     5,6
        fcb     8,8
        fcb     11,10
        fcb     14,12
        fcb     17,14
        fcb     20,16
        fcb     23,18
        fcb     26,20
        fcb     28,22
        fcb     25,4
        fcb     22,6
        fcb     19,8
        fcb     16,10
        fcb     13,12
        fcb     10,14
        fcb     7,16
        fcb     4,18

Level4BombPositions:
        fcb     2,2
        fcb     6,2
        fcb     10,2
        fcb     14,2
        fcb     18,2
        fcb     22,2
        fcb     26,2
        fcb     29,4
        fcb     29,7
        fcb     29,10
        fcb     25,13
        fcb     21,13
        fcb     17,13
        fcb     13,13
        fcb     9,17
        fcb     5,17
        fcb     2,20
        fcb     6,22

Level5BombPositions:
        fcb     14,3
        fcb     16,3
        fcb     12,5
        fcb     18,5
        fcb     10,7
        fcb     20,7
        fcb     8,10
        fcb     22,10
        fcb     6,13
        fcb     24,13
        fcb     8,16
        fcb     22,16
        fcb     10,19
        fcb     20,19
        fcb     12,21
        fcb     18,21
        fcb     14,22
        fcb     16,22

Level6BombPositions:
        fcb     1,3
        fcb     5,5
        fcb     9,7
        fcb     13,9
        fcb     17,11
        fcb     21,13
        fcb     25,15
        fcb     29,17
        fcb     25,19
        fcb     21,21
        fcb     17,22
        fcb     13,20
        fcb     9,18
        fcb     5,16
        fcb     1,14
        fcb     5,11
        fcb     13,6
        fcb     23,6

Level7BombPositions:
        fcb     4,4
        fcb     8,4
        fcb     12,4
        fcb     18,4
        fcb     22,4
        fcb     26,4
        fcb     4,9
        fcb     8,9
        fcb     12,9
        fcb     18,9
        fcb     22,9
        fcb     26,9
        fcb     4,14
        fcb     8,14
        fcb     22,14
        fcb     26,14
        fcb     10,21
        fcb     20,21

Level8BombPositions:
        fcb     15,2
        fcb     11,4
        fcb     19,4
        fcb     7,6
        fcb     23,6
        fcb     3,8
        fcb     27,8
        fcb     5,12
        fcb     25,12
        fcb     9,15
        fcb     21,15
        fcb     13,18
        fcb     17,18
        fcb     3,21
        fcb     7,21
        fcb     23,21
        fcb     27,21
        fcb     15,22

Level9BombPositions:
        fcb     2,5
        fcb     5,5
        fcb     8,5
        fcb     11,5
        fcb     14,5
        fcb     17,5
        fcb     20,5
        fcb     23,5
        fcb     26,5
        fcb     29,5
        fcb     27,10
        fcb     23,12
        fcb     19,14
        fcb     15,16
        fcb     11,18
        fcb     7,20
        fcb     3,22
        fcb     28,22

Level10BombPositions:
        fcb     1,2
        fcb     4,2
        fcb     7,4
        fcb     10,4
        fcb     13,6
        fcb     16,6
        fcb     19,8
        fcb     22,8
        fcb     25,10
        fcb     28,10
        fcb     25,14
        fcb     22,14
        fcb     19,16
        fcb     16,16
        fcb     13,18
        fcb     10,18
        fcb     7,21
        fcb     4,21
