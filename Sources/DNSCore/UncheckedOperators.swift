infix operator &-- : AdditionPrecedence

@inlinable
@_transparent
package func &-- <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &- rhs
    assert(result == (lhs - rhs))
    return result
}

infix operator &-== : AssignmentPrecedence

@inlinable
@_transparent
package func &-== <I: FixedWidthInteger>(lhs: inout I, rhs: I) {
    assert((lhs &- rhs) == (lhs - rhs))
    lhs &-= rhs
}

infix operator &++ : AdditionPrecedence

@inlinable
@_transparent
package func &++ <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &+ rhs
    assert(result == (lhs + rhs))
    return result
}

infix operator &+== : AssignmentPrecedence

@inlinable
@_transparent
package func &+== <I: FixedWidthInteger>(lhs: inout I, rhs: I) {
    assert((lhs &+ rhs) == (lhs + rhs))
    lhs &+= rhs
}

infix operator &** : MultiplicationPrecedence

@inlinable
@_transparent
package func &** <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &* rhs
    assert(result == (lhs * rhs))
    return result
}

infix operator &>>> : BitwiseShiftPrecedence

@inlinable
@_transparent
package func &>>> <I: FixedWidthInteger>(lhs: I, rhs: some FixedWidthInteger) -> I {
    let result = lhs &>> rhs
    assert(result == (lhs >> rhs))
    return result
}

infix operator &>>== : AssignmentPrecedence

@inlinable
@_transparent
package func &>>== <I: FixedWidthInteger>(lhs: inout I, rhs: some FixedWidthInteger) {
    assert((lhs &>> rhs) == (lhs >> rhs))
    lhs &>>= rhs
}

infix operator &<<< : BitwiseShiftPrecedence

@inlinable
@_transparent
package func &<<< <I: FixedWidthInteger>(lhs: I, rhs: some FixedWidthInteger) -> I {
    let result = lhs &<< rhs
    assert(result == (lhs << rhs))
    return result
}

infix operator &<<== : AssignmentPrecedence

@inlinable
@_transparent
package func &<<== <I: FixedWidthInteger>(lhs: inout I, rhs: some FixedWidthInteger) {
    assert((lhs &<< rhs) == (lhs << rhs))
    lhs &<<= rhs
}
