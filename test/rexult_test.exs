defmodule RexultTest do
  use ExUnit.Case
  doctest Rexult
  import Rexult

  describe "is_rexult!/1" do
    test "returns ok result unchanged" do
      result = {:ok, "value"}
      assert is_rexult!(result) == result
    end

    test "returns error result unchanged" do
      result = {:error, "reason"}
      assert is_rexult!(result) == result
    end

    test "returns break result unchanged" do
      result = {:break, {:ok, "value"}}
      assert is_rexult!(result) == result
    end

    test "raises for non-result values" do
      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!("not a result")
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!(42)
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!(nil)
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!(:ok)
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!(:error)
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!([1, 2, 3])
      end

      assert_raise RuntimeError, "is not result", fn ->
        is_rexult!(%{key: "value"})
      end
    end
  end

  describe "ok?/1" do
    test "returns true for ok tuples" do
      assert ok?({:ok, "value"}) == true
    end

    test "returns false for error tuples" do
      assert ok?({:error, "reason"}) == false
    end

    test "returns false for break with ok" do
      assert ok?({:break, {:ok, "value"}}) == false
    end

    test "returns false for break with error" do
      assert ok?({:break, {:error, "reason"}}) == false
    end
  end

  describe "ok_and_then/2" do
    test "chains successful operations" do
      result = ok_and_then({:ok, 5}, fn x -> {:ok, x * 2} end)
      assert result == {:ok, 10}
    end

    test "returns error when first operation fails" do
      result = ok_and_then({:error, "failed"}, fn x -> {:ok, x * 2} end)
      assert result == {:error, "failed"}
    end

    test "passes through break without calling function" do
      result = ok_and_then({:break, {:ok, 5}}, fn x -> {:ok, x * 2} end)
      assert result == {:break, {:ok, 5}}
    end
  end

  describe "all_ok/1" do
    test "all values are ok" do
      result = [ok!(5), ok!("hello")] |> all_ok()
      assert result == {:ok, [5, "hello"]}
    end

    test "returns error when there is an error" do
      result = [ok!(5), ok!("hello"), err!("tacos")] |> all_ok()
      assert result == {:error, "tacos"}
    end
  end

  describe "split_ok_err/2" do
    test "splits mixed list of ok and error results" do
      results = [ok!(1), err!("error1"), ok!(2), err!("error2"), ok!(3)]
      {oks, errs} = split_ok_err(results)
      assert oks == [1, 2, 3]
      assert errs == ["error1", "error2"]
    end

    test "handles empty list" do
      {oks, errs} = split_ok_err([])
      assert oks == []
      assert errs == []
    end

    test "handles list with only ok results" do
      results = [ok!("hello"), ok!(42), ok!(:atom)]
      {oks, errs} = split_ok_err(results)
      assert oks == ["hello", 42, :atom]
      assert errs == []
    end

    test "handles list with only error results" do
      results = [err!("fail1"), err!(:timeout), err!(404)]
      {oks, errs} = split_ok_err(results)
      assert oks == []
      assert errs == ["fail1", :timeout, 404]
    end
  end
end
