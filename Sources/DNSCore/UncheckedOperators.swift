infix operator &-- : AdditionPrecedence

@inlinable
@inline(__always)
package func &-- <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &- rhs
    assert(result == (lhs - rhs))
    return result
}

infix operator &-== : AssignmentPrecedence

@inlinable
@inline(__always)
package func &-== <I: FixedWidthInteger>(lhs: inout I, rhs: I) {
    assert((lhs &- rhs) == (lhs - rhs))
    lhs &-= rhs
}

infix operator &++ : AdditionPrecedence

@inlinable
@inline(__always)
package func &++ <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &+ rhs
    assert(result == (lhs + rhs))
    return result
}

infix operator &+== : AssignmentPrecedence

@inlinable
@inline(__always)
package func &+== <I: FixedWidthInteger>(lhs: inout I, rhs: I) {
    assert((lhs &+ rhs) == (lhs + rhs))
    lhs &+= rhs
}

infix operator &** : MultiplicationPrecedence

@inlinable
@inline(__always)
package func &** <I: FixedWidthInteger>(lhs: I, rhs: I) -> I {
    let result = lhs &* rhs
    assert(result == (lhs * rhs))
    return result
}

infix operator &>>> : BitwiseShiftPrecedence

@inlinable
@inline(__always)
package func &>>> <I: FixedWidthInteger>(lhs: I, rhs: some FixedWidthInteger) -> I {
    let result = lhs &>> rhs
    assert(result == (lhs >> rhs))
    return result
}

infix operator &>>== : AssignmentPrecedence

@inlinable
@inline(__always)
package func &>>== <I: FixedWidthInteger>(lhs: inout I, rhs: some FixedWidthInteger) {
    assert((lhs &>> rhs) == (lhs >> rhs))
    lhs &>>= rhs
}

infix operator &<<< : BitwiseShiftPrecedence

@inlinable
@inline(__always)
package func &<<< <I: FixedWidthInteger>(lhs: I, rhs: some FixedWidthInteger) -> I {
    let result = lhs &<< rhs
    assert(result == (lhs << rhs))
    return result
}

infix operator &<<== : AssignmentPrecedence

@inlinable
@inline(__always)
package func &<<== <I: FixedWidthInteger>(lhs: inout I, rhs: some FixedWidthInteger) {
    assert((lhs &<< rhs) == (lhs << rhs))
    lhs &<<= rhs
}
