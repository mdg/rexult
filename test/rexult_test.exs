defmodule RexultTest do
  use ExUnit.Case
  doctest Rexult

  describe "is_result!/1" do
    test "returns ok result unchanged" do
      result = {:ok, "value"}
      assert Rexult.is_result!(result) == result
    end

    test "returns error result unchanged" do
      result = {:error, "reason"}
      assert Rexult.is_result!(result) == result
    end

    test "returns break result unchanged" do
      result = {:break, {:ok, "value"}}
      assert Rexult.is_result!(result) == result
    end

    test "raises for non-result values" do
      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!("not a result")
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!(42)
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!(nil)
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!(:ok)
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!(:error)
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!([1, 2, 3])
      end

      assert_raise RuntimeError, "is not result", fn ->
        Rexult.is_result!(%{key: "value"})
      end
    end
  end

  describe "ok?/1" do
    test "returns true for ok tuples" do
      assert Rexult.ok?({:ok, "value"}) == true
    end

    test "returns false for error tuples" do
      assert Rexult.ok?({:error, "reason"}) == false
    end

    test "returns false for break with ok" do
      assert Rexult.ok?({:break, {:ok, "value"}}) == false
    end

    test "returns false for break with error" do
      assert Rexult.ok?({:break, {:error, "reason"}}) == false
    end

    test "returns false for nil" do
      assert Rexult.ok?(nil) == false
    end
  end
end
