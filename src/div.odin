package main

// __umoddi3 (unsigned modulo double integer into 3 parts)
@(export, link_name="__umoddi3")
__umoddi3 :: proc "c" (a, b: u64) -> u64 {
    if b == 0 do return 0

    num, den := a, b
    shift: u64 = 0

    for den <= num && (den & (1 << 63)) == 0 {
        den <<= 1
        shift += 1
    }

    rem := num

    for i in 0..=shift {
        if rem >= den {
            rem -= den
        }
        den >>= 1
    }

    return rem
}

// __udivdi3 (unsigned integer division of double-word integers into 3 parts)
@(export, link_name="__udivdi3")
__udivdi3 :: proc "c" (a, b: u64) -> u64 {
    if b == 0 do return 0

    num, den := a, b
    shift: u64 = 0

    for den <= num && (den & (1 << 63)) == 0 {
        den <<= 1
        shift += 1
    }

    rem := num
    quot: u64 = 0

    for i in 0..=shift {
        quot <<= 1
        if rem >= den {
            rem -= den
            quot |= 1
        }
        den >>= 1
    }

    return quot
}
