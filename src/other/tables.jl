using Tables, IteratorInterfaceExtensions

Tables.istable(::Type{<:AbstractDataFrame}) = true
Tables.columnaccess(::Type{<:AbstractDataFrame}) = true
Tables.columns(df::AbstractDataFrame) = df
Tables.rowaccess(::Type{DataFrame}) = true
Tables.rows(df::DataFrame) = Tables.rows(columntable(df))

Tables.schema(df::AbstractDataFrame) = Tables.Schema(names(df), eltypes(df))
Tables.schema(df::DFRowIterator) = Tables.schema(df.df)

@inline function Base.getproperty(r::DataFrameRow, ::Type{T}, col::Int, nm::Symbol) where {T}
    @inbounds v = (getfield(getfield(r, 1), 1)[col])[getfield(r, 2)]::T
    return v
end

getvector(x::AbstractVector) = x
getvector(x) = collect(x)
fromcolumns(x, makeunique) = DataFrame(Any[getvector(c) for c in Tables.eachcolumn(x)], collect(Symbol, propertynames(x)); makeunique=makeunique)

function DataFrame(x::T; makeunique::Bool=false) where {T}
    if Tables.istable(T)
        return fromcolumns(Tables.columns(x), makeunique)
    end
    y = IteratorInterfaceExtensions.getiterator(x)
    yT = typeof(y)
    if Base.isiterable(yT)
        # Base.depwarn("constructing a DataFrame from an iterator is deprecated; $T should support the Tables.jl interface", nothing)
        if Base.IteratorEltype(yT) === Base.HasEltype() && eltype(y) <: NamedTuple
            return fromcolumns(Tables.columns(Tables.DataValueUnwrapper(y)), makeunique)
        else
            # non-NamedTuple or UnknownEltype
            return fromcolumns(Tables.buildcolumns(nothing, Tables.DataValueUnwrapper(y)), makeunique)
        end
    end
    throw(ArgumentError("unable to construct DataFrame from $T"))
end

Base.append!(df::DataFrame, x) = append!(df, DataFrame(x))

# This supports the Tables.RowTable type; needed to avoid ambiguities w/ another constructor
DataFrame(x::Vector{T}; makeunique::Bool=false) where {T <: NamedTuple} = fromcolumns(Tables.columns(x), makeunique)

IteratorInterfaceExtensions.getiterator(df::DataFrame) = Tables.datavaluerows(df)
IteratorInterfaceExtensions.isiterable(x::DataFrame) = true