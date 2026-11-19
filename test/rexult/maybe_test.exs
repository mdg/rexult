defmodule Rexult.MaybeTest do
  use ExUnit.Case, async: true

  alias Rexult.Maybe

  describe "and_then/2" do
    test "returns nil without calling the function when value is nil" do
      assert Maybe.and_then(nil, fn _ -> flunk("should not be called") end) == nil
    end

    test "applies the function to a non-nil value" do
      assert Maybe.and_then(2, fn x -> x * 3 end) == 6
    end

    test "passes the function's nil result through" do
      assert Maybe.and_then(1, fn _ -> nil end) == nil
    end

    test "allows chaining" do
      result =
        5
        |> Maybe.and_then(fn x -> x + 1 end)
        |> Maybe.and_then(fn x -> x * 2 end)

      assert result == 12
    end
  end

  describe "and_if/3" do
    test "returns nil without calling the function when value is nil and condition is true" do
      assert Maybe.and_if(nil, true, fn _ -> flunk("should not be called") end) == nil
    end

    test "returns nil without calling the function when value is nil and condition is false" do
      assert Maybe.and_if(nil, false, fn _ -> flunk("should not be called") end) == nil
    end

    test "returns value unchanged without calling the function when condition is false" do
      assert Maybe.and_if(:value, false, fn _ -> flunk("should not be called") end) == :value
    end

    test "applies the function when condition is true" do
      assert Maybe.and_if(4, true, fn x -> x + 1 end) == 5
    end

    test "returns the function's nil result when condition is true" do
      assert Maybe.and_if(4, true, fn _ -> nil end) == nil
    end

    test "raises a FunctionClauseError when condition is not a boolean" do
      not_a_boolean = String.to_atom("yes")

      assert_raise FunctionClauseError, fn ->
        Maybe.and_if(nil, not_a_boolean, fn x -> x end)
      end
    end
  end

  describe "and_both/3" do
    test "returns nil when the first value is nil" do
      assert Maybe.and_both(nil, 1, fn _, _ -> flunk("should not be called") end) == nil
    end

    test "returns nil when both values are nil" do
      assert Maybe.and_both(nil, nil, fn _, _ -> flunk("should not be called") end) == nil
    end

    test "returns the first value when the other value is nil" do
      assert Maybe.and_both(:first, nil, fn _, _ -> flunk("should not be called") end) == :first
    end

    test "calls the function with both values when neither is nil" do
      assert Maybe.and_both(2, 3, fn a, b -> a + b end) == 5
    end

    test "returns the function's nil result when both values are present" do
      assert Maybe.and_both(2, 3, fn _, _ -> nil end) == nil
    end
  end

  describe "or_default/2" do
    test "returns the default when the value is nil" do
      assert Maybe.or_default(nil, :default) == :default
    end

    test "returns the value when it is not nil" do
      assert Maybe.or_default(:value, :default) == :value
    end

    test "keeps falsy non-nil values such as false" do
      assert Maybe.or_default(false, :default) == false
    end

    test "keeps zero" do
      assert Maybe.or_default(0, 10) == 0
    end
  end

  describe "or_else/2" do
    test "calls the function and returns its result when the value is nil" do
      assert Maybe.or_else(nil, fn -> :computed end) == :computed
    end

    test "does not call the function when the value is not nil" do
      assert Maybe.or_else(:value, fn -> flunk("should not be called") end) == :value
    end

    test "keeps falsy non-nil values such as false" do
      assert Maybe.or_else(false, fn -> flunk("should not be called") end) == false
    end
  end
end
