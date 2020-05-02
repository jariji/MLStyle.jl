module Record
using MLStyle
using MLStyle.MatchCore
using MLStyle.MatchImpl
using MLStyle.AbstractPattern
using MLStyle.AbstractPattern.BasicPatterns

export @as_record


function P_partial_struct_decons(t, partial_fields, ps, prepr::AbstractString="$t")
    function tcons(_...)
        t
    end
    
    comp = PComp(
        prepr, tcons;
    )
    function extract(sub, i::Int)
        :($sub.$(partial_fields[i]))
    end
    decons(comp, extract, ps)
end

function mk_code(Struct, line::LineNumberNode)
    quote
        $line
        function $MatchImpl.pattern_compile(t::Type{$Struct}, self::Function, type_params, type_args, args)
            $line
            isempty(type_params) || return begin
                call = Expr(:call, t, args...)
                ann = Expr(:curly, t, type_args...)
                self(Where(call, ann, type_params))
            end
            all_field_names = fieldnames(t)
            partial_field_names = Symbol[]
            patterns = Function[]
            $MatchImpl.@switch args begin    
            @case [Expr(:parameters, kwargs...), args...]
                @goto endswitch
            @case let kwargs = [] end
                @goto endswitch
            end
            @label endswitch
            n_args = length(args)
            if length(all_field_names) === n_args
                append!(patterns, map(self, args))
                append!(partial_field_names, all_field_names)
            elseif n_args !== 0
                error("count of positional fields should be 0 or the same as the fields($all_field_names)")
            end
            for e in kwargs
                $MatchImpl.@switch e begin
                @case :: Symbol
                    e in all_field_names || error("unknown field name $e for $t when field punnning.")
                    push!(partial_field_names, e)
                    push!(patterns, $P_capture(e))
                    continue
                @case Expr(:kw, key::Symbol, value)
                    key in all_field_names || error("unknown field name $key for $t when field punnning.")
                    push!(partial_field_names, key)
                    push!(patterns, $and([$P_capture(key), self(value)]))
                    continue
                @case _
                    
                    error("unknown sub-pattern $e in " * string(t) * ".")
                end
            end
            
            
            ret = $P_partial_struct_decons(t, partial_field_names, patterns)
            isempty(type_args) && return ret
            $and([self(Expr(:(::), Expr(:curly, t, type_args))) , ret])
        end
    end
end


function as_record(n, line)
    @switch n begin
    @case ::Symbol
        return mk_code(n, line)
    @case Expr(:struct, _, :($hd{$(_...)}), _...) ||
          Expr(:struct, _, hd, _...)
        return Expr(:block,
            n,
            mk_code(hd, line)
        )
    @case _
        error("malformed structure $n")
    end
end

function _depwarn(o)
    trunc = min(length(o), 20)
    s = SubString(string(o), 1:trunc)
    Base.depwarn(
        "When definining $(s):" *
        "Scoping specifiers such as `internal`, `public` are deprecated." *
        "Now the scope of a pattern is consistent with the visibility of the pattern object in current module."
    )
end

macro as_record(_, n)
    _depwarn(n)
    esc(as_record(n, __source__))
end

macro as_record(n)
    esc(as_record(n, __source__))
end

end

