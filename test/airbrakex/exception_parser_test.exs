defmodule Airbrakex.ExceptionParserTest do
  use ExUnit.Case

  test "should parse exception" do
    {exception, stacktrace} =
      try do
        IO.inspect("test", [], "")
      rescue
        e -> {e, __STACKTRACE__}
      end

    result = %{
      message: "no function clause matching in IO.inspect/3",
      type: "FunctionClauseError",
      backtrace: [
        %{file: "(IO) lib/io.ex", function: "inspect(\"test\", [], \"\")", line: 431},
        %{
          file: "(Airbrakex.ExceptionParserTest) test/airbrakex/exception_parser_test.exs",
          function: "test should parse exception/1",
          line: 7
        },
        %{file: "(ExUnit.Runner) lib/ex_unit/runner.ex", function: "exec_test/1", line: 502},
        %{file: "(timer) timer.erl", function: "tc/1", line: 166},
        %{
          file: "(ExUnit.Runner) lib/ex_unit/runner.ex",
          function: "-spawn_test_monitor/4-fun-1-/4",
          line: 453
        }
      ]
    }

    assert Airbrakex.ExceptionParser.parse(:error, exception, stacktrace) == result
  end

  test "should parse BadMapError (otp 24)" do
    {exception, stacktrace} =
      try do
        nil |> Map.keys()
      rescue
        e -> {e, __STACKTRACE__}
      end

    result = %{
      backtrace: [
        %{
          file: "erl_stdlib_errors",
          function: "maps.keys(nil)",
          line: 0
        },
        %{
          file: "(Airbrakex.ExceptionParserTest) test/airbrakex/exception_parser_test.exs",
          function: "test should parse BadMapError (otp 24)/1",
          line: 38
        },
        %{
          file: "(ExUnit.Runner) lib/ex_unit/runner.ex",
          function: "exec_test/1",
          line: 502
        },
        %{
          file: "(timer) timer.erl",
          function: "tc/1",
          line: 166
        },
        %{
          file: "(ExUnit.Runner) lib/ex_unit/runner.ex",
          function: "-spawn_test_monitor/4-fun-1-/4",
          line: 453
        }
      ],
      message: "expected a map, got: nil",
      type: "BadMapError"
    }

    assert Airbrakex.ExceptionParser.parse(:error, exception, stacktrace) == result
  end
end
