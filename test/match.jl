@testset "match" begin
    @testset "literal match" begin
        simple_match(x) = @match x begin
            1  => "wrong!"
            2  => "wrong!"
            10 => "right!"
            _  => "None" end
        @test simple_match(10) == "right!"
        @test simple_match(1) == "wrong!"
        @test simple_match(0) == "None"
    end
    @testset "capture match with guard" begin
        capture_match(x) = @match x begin
            x && if x > 0 end => x + 1
            x && if x < 0 end => x - 1
            _ => 0
        end
        @test_skip capture_match(0) == 0
        @test_skip capture_match(1) == 2
        @test_skip capture_match(-1) == -2
    end
    @testset "type match" begin
        type_match(x) = @match x begin
            ::Float64  => nothing
            b :: Int   => b
            _          => nothing
        end
        @test type_match(3.0) == nothing
        @test type_match(3) == 3
        @test type_match("3") == nothing
    end
    @testset "as match" begin
        as_match(x) = @match x begin
            (a, b) && c => c[1] == a && c[2] == b
        end
        @test as_match((:a, :b)) == true
        @test as_match((1, 2)) == true
    end
    @testset "guard match" begin
        guard_match(x) = @match x begin
            x && if x > 5 end => 5 - x # only succeed when x > 5
            _        => 1
        end
        @test_skip guard_match(0) == 1
        @test_skip guard_match(10) == -5
    end
    # Personally I think range match is not that useful
    # since we already have guard
    # A: not only for range, it's enumerable..


    @testset "range match" begin
        range_match(x) = @match x begin
            1:10  && x => "$x in [1, 10]"
            11:20 && x => "$x in [11, 20]"
            21:30 && x => "$x in [21, 30]"
        end
        @test range_match(3) == "3 in [1, 10]"
        @test range_match(13) == "13 in [11, 20]"
        @test range_match(23) == "23 in [21, 30]"
    end

    @testset "reference match" begin
        c = "abc"
        ref_match(x,y) = @match (x, y) begin
            (&c, _)  => "x equals to c!"
            (_,  &c) => "y equals to c!"
            _        => "none of x and y equal to c"
        end
        @test ref_match("abc", "def") == "x equals to c!"
        @test ref_match("def", "abc") == "y equals to c!"
        @test ref_match(0, 0) == "none of x and y equal to c"
    end
    # TODO: custom pattern is not fully understood yet...
    @testset "dict match" begin
        dict_match(dict) = @match dict begin
            Dict("3" => four::Int,
                 5   => Dict(6 => sev)) && if four < sev end => sev
        end
        @test dict_match(Dict(1 => 2, "3" => 4, 5 => Dict(6 => 7))) == 7
    end
    @testset "tuple match" begin
        @test (1, 2, 3, 4) == @match (1, 2, (3, 4, (5, ))) begin
            (a, b, (c, d, (5, ))) => (a, b, c, d)
        end
    end
    @testset "array match" begin
        @test ([2, 3], 4) == @match [1, 2, 3, 4] begin
            [1, pack..., a] => (pack, a)
            end
        # @test ([3, 2], 4) == @match [1 2; 3 4] begin
        #     [1, pack..., a] => (pack, a)
        #     end
        @test ([2, 3], 4) == @match [1, 2, 3, 4] begin
            [1, pack..., a] => (pack, a)
            end
    end
    @testset "AST match" begin
        function ast_match(a)
            @match a begin
            :x       => 0
            :(x + 1) => 1
            :(x + 2) => 2
            _        => 3
            end
        end
        @test ast_match(:(x + 1)) === 1
        @test ast_match(:(x + 2)) === 2
        @test ast_match(:x)       === 0
        @test ast_match(:(x + 5)) === 3
    end

    @testset "QuoteNode" begin
        function ast_match(a)
            @match a begin
            QuoteNode(:($x + $y)) => (x, y)
            _ => nothing
            end
        end
        @test ast_match(QuoteNode(:(x + 1))) === (:x, 1)
        @test ast_match(QuoteNode(:(x + 2))) === (:x, 2)
        @test ast_match(QuoteNode(1)) === nothing
        @test ast_match(:x)       === nothing
    end

    @testset "one-liner match" begin
        @test (@match 1 1 => 2) == 2
        @test (@match [1, 2, 3] [hd, tl...] => (hd, tl)) == (1, [2,3])
    end

    @testset "trymatch" begin
        val = @trymatch true begin
            ::Int => 1
        end
        @test val === nothing
    end
end

@test_macro_throws ArgumentError @match 1 begin
end
