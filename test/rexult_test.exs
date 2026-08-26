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

    test "converts bare :error to error tuple" do
      assert rexult!(:error) == {:error, :error}
    end
  end

  describe "is_ok/1 guard" do
    test "returns true for ok tuples" do
      assert is_ok({:ok, "value"})
    end

    test "returns false for error tuples" do
      refute is_ok({:error, "reason"})
    end

    test "returns false for break tuples" do
      refute is_ok({:break, {:ok, "value"}})
    end

    test "returns false for non-rexult values" do
      refute is_ok(:ok)
      refute is_ok(nil)
      refute is_ok({:ok, 1, 2})
    end
  end

  describe "is_err/1 guard" do
    test "returns true for error tuples" do
      assert is_err({:error, "reason"})
    end

    test "returns false for ok tuples" do
      refute is_err({:ok, "value"})
    end

    test "returns false for break tuples" do
      refute is_err({:break, {:error, "reason"}})
    end

    test "returns false for non-rexult values" do
      refute is_err(:error)
      refute is_err(nil)
      refute is_err({:error, 1, 2})
    end
  end

  describe "is_break/1 guard" do
    test "returns true for break tuples" do
      assert is_break({:break, {:ok, "value"}})
    end

    test "returns false for ok tuples" do
      refute is_break({:ok, "value"})
    end

    test "returns false for error tuples" do
      refute is_break({:error, "reason"})
    end

    test "returns false for non-rexult values" do
      refute is_break(:break)
      refute is_break(nil)
      refute is_break({:break, 1, 2})
    end
  end

  describe "is_ok_err/1 guard" do
    test "returns true for ok tuples" do
      assert is_ok_err({:ok, "value"})
    end

    test "returns true for error tuples" do
      assert is_ok_err({:error, "reason"})
    end

    test "returns false for break tuples" do
      refute is_ok_err({:break, {:ok, "value"}})
    end

    test "returns false for non-rexult values" do
      refute is_ok_err(nil)
      refute is_ok_err(:ok)
    end
  end

  describe "is_rexult/1 guard" do
    test "returns true for ok tuples" do
      assert is_rexult({:ok, "value"})
    end

    test "returns true for error tuples" do
      assert is_rexult({:error, "reason"})
    end

    test "returns true for break tuples" do
      assert is_rexult({:break, {:ok, "value"}})
    end

    test "returns false for non-rexult values" do
      refute is_rexult(nil)
      refute is_rexult(:ok)
      refute is_rexult({:ok, 1, 2})
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

  describe "map_ok/2" do
    test "maps ok value" do
      assert map_ok({:ok, 5}, fn x -> x * 2 end) == {:ok, 10}
    end

    test "normalizes bare :error" do
      assert map_ok(:error, fn x -> x * 2 end) == {:error, :error}
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

    test "normalizes bare :error" do
      result = ok_and_then(:error, fn x -> {:ok, x * 2} end)
      assert result == {:error, :error}
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
