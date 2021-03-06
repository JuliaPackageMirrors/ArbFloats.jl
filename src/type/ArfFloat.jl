#=
            # P is the precision used for this value
type ArfFloat{P}  <: Real
  exponentOf2::Int # fmpz
  nwords_sign::UInt # mp_size_t
  significand1::UInt # significand_struct
  significand2::UInt
end
=#

precision{P}(x::ArfFloat{P}) = P
precision{P}(::Type{ArfFloat{P}}) = P
precision(::Type{ArfFloat}) = ArbFloatPrecision[1]
setprecision(::Type{ArfFloat}, x::Int) = setprecision(ArbFloat, x)

# a type specific hash function helps the type to 'just work'
const hash_arffloat_lo = (UInt === UInt64) ? 0x37e642589da3416a : 0x5d46a6b4
const hash_0_arffloat_lo = hash(zero(UInt), hash_arffloat_lo)
hash{P}(z::ArfFloat{P}, h::UInt) =
    hash(reinterpret(UInt,z.significand1)$z.exponentOf2,
         (h $ hash(z.significand2$(~reinterpret(UInt,P)), hash_arffloat_lo) $ hash_0_arffloat_lo))


# empty constructor
ArfFloat() = ArfFloat{precision(ArfFloat)}()


weakcopy{P}(x::ArfFloat{P}) = WeakRef(x)

function copy{T<:ArfFloat}(x::T)
    z = T()
    ccall(@libarb(arf_set), Void, (Ptr{T}, Ptr{T}), &z, &x)
    return z
end

function deepcopy{T<:ArfFloat}(x::T)
    z = T()
    ccall(@libarb(arf_set), Void, (Ptr{T}, Ptr{T}), &z, &x)
    return z
end


function zero{T<:ArfFloat}(::Type{T})
   z = T()
   return z
end
#zero{P}(x::ArfFloat{P}) = zero(ArfFloat{P})

function zero{T<:ArfFloat}(x::T)
    P = precision(T)
    return zero( ArfFloat{P} )
end

function one{T<:ArfFloat}(::Type{T})
    z = T()
    ccall(@libarb(arf_set_si), Void, (Ptr{ArfFloat}, Int), &z, one(Int))
    return z
end

function one{T<:ArfFloat}(x::T)
    P = precision(T)
    return one( ArfFloat{P} )
end


function isnan{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_nan), Cint, (Ptr{T},), &x)
end
function isinf{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_inf), Cint, (Ptr{T},), &x)
end
function isposinf{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_pos_inf), Cint, (Ptr{T},), &x)
end
function isneginf{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_neg_inf), Cint, (Ptr{T},), &x)
end
function iszero{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_zero), Cint, (Ptr{T},), &x)
end
function isone{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_one), Cint, (Ptr{T},), &x)
end
function isfinite{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_finite), Cint, (Ptr{T},), &x)
end
function isnormal{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_normal), Cint, (Ptr{T},), &x)
end
function isspecial{T<:ArfFloat}(x::T)
    zero(Cint) != ccall(@libarb(arf_is_special), Cint, (Ptr{T},), &x)
end

function notnan{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_nan), Cint, (Ptr{T},), &x)
end
function notinf{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_inf), Cint, (Ptr{T},), &x)
end
function notposinf{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_pos_inf), Cint, (Ptr{T},), &x)
end
function notneginf{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_neg_inf), Cint, (Ptr{T},), &x)
end
function notzero{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_zero), Cint, (Ptr{T},), &x)
end
function notone{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_one), Cint, (Ptr{T},), &x)
end
function notfinite{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_finite), Cint, (Ptr{T},), &x)
end
function notnormal{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_normal), Cint, (Ptr{T},), &x)
end
function notspecial{T<:ArfFloat}(x::T)
    zero(Cint) == ccall(@libarb(arf_is_special), Cint, (Ptr{T},), &x)
end


function convert{P}(::Type{BigFloat}, x::ArfFloat{P})
    z = zero(BigFloat)
    r = ccall(@libarb(arf_get_mpfr), Int, (Ptr{BigFloat}, Ptr{ArfFloat{P}}, Cint), &z, &x, 0)
    return z
end

function convert{P}(::Type{ArfFloat{P}}, x::BigFloat)
    z = ArfFloat{P}()
    ccall(@libarb(arf_set_mpfr), Void, (Ptr{ArfFloat{P}}, Ptr{BigFloat}), &z, &x)
    z
end
convert(::Type{ArfFloat}, x::BigFloat) = convert(ArfFloat{precision(ArfFloat)}, x)

convert{T<:ArfFloat}(::Type{T}, x::BigInt) = convert(T, convert(BigFloat, x))
convert{P}(::Type{ArfFloat{P}}, x::BigInt) = convert(ArfFloat{P}, convert(BigFloat, x))

function convert{P}(::Type{ArfFloat{P}}, x::Int64)
    z = ArfFloat{P}()
    ccall(@libarb(arf_set_si), Void, (Ptr{ArfFloat{P}}, Ptr{Int64}), &z, &x)
    z
end
convert(::Type{ArfFloat}, x::Int64) = convert(ArfFloat{precision(ArfFloat)}, x)

function convert{P}(::Type{ArfFloat{P}}, x::Float64)
    z = ArfFloat{P}()
    ccall(@libarb(arf_set_d), Void, (Ptr{ArfFloat{P}}, Ptr{Float64}), &z, &x)
    z
end
convert(::Type{ArfFloat}, x::Float64) = convert(ArfFloat{precision(ArfFloat)}, x)

midpoint{P}(x::ArfFloat{P}) = x

radius{P}(x::ArfFloat{P}) = zero(ArfFloat{P})


#=
#define ARF_RND_DOWN FMPR_RND_DOWN
#define ARF_RND_UP FMPR_RND_UP
#define ARF_RND_FLOOR FMPR_RND_FLOOR
#define ARF_RND_CEIL FMPR_RND_CEIL
#define ARF_RND_NEAR FMPR_RND_NEAR
=#

function round{T<:ArfFloat}(x::T, prec::Int64)
    P = precision(T)
    z = ArfFloat{P}()
    ccall(@libarb(arf_set_round), Int, (Ptr{T}, Ptr{T}, Int64, Int), &z, &x, prec, 2)
    return z
end


#=
function frexp{P}(x::ArfFloat{P})
   significand = ArfFloat{P}()
   exponentOf2 = zero(Int64)
   ccall(@libarb(arf_frexp), Void, (Ptr{ArfFloat{P}}, Int64, Ptr{ArfFloat{P}}), &significand, exponentOf2, &x)
   significand, exponentOf2
end
=#

function min{T<:ArfFloat}(x::T, y::T)
    c = ccall(@libarb(arf_cmp), Cint, (Ptr{T}, Ptr{T}), &x, &y)
    return (c < 0) ? x : y
end

function max{T<:ArfFloat}(x::T, y::T)
    c = ccall(@libarb(arf_cmp), Cint, (Ptr{T}, Ptr{T}), &x, &y)
    return (c > 0) ? x : y
end
