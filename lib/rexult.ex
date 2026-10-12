defmodule Rexult do
  @moduledoc """
  Result type library

  ## Description

  Philosophy is to be strict on typing and raise errors when inputs
  are unexpected.

  The library interface is designed to be required and imported

  ## Reference

  [doc.rust-lang.org/std/result/](https://doc.rust-lang.org/std/result/)
  """

  @type t() :: {:ok, any()} | {:error, any()} | {:break, t()}
  @type t(sub) :: {:ok, sub} | {:error, any()} | {:break, t(sub)}

  defguard _is_ok_err(r) when is_tuple(r) and tuple_size(r) == 2 and elem(r, 0) in [:ok, :err]

  defguard _is_rexult(r) when is_tuple(r) and tuple_size(r) == 2 and elem(r, 0) in [:ok, :err, :break]

  defguard is_ok(r) when is_tuple(r) and tuple_size(r) == 2 and elem(r, 0) == :ok and not _is_rexult(elem(r, 1))

  defguard is_err(r) when is_tuple(r) and tuple_size(r) == 2 and elem(r, 0) == :error and not _is_rexult(elem(r, 1))

  defguard is_ok_err(r) when is_ok(r) or is_err(r)

  defguard is_break(r) when is_tuple(r) and tuple_size(r) == 2 and elem(r, 0) == :break and is_ok_err(elem(r, 1))

  defguard is_rexult(r) when is_ok_err(r) or is_break(r)

  @doc """
  Wrap an ok value into an {:ok, tuple} or return the error in an {:error, tuple}

  The cases of :ok -> {:ok, :ok} and :error -> {:error, :error} are a little weird
  But they normalize the output, so going to stick with it.
  Converting them to any other value will be misleading and leaving them
  as bare :ok or :error will cause match case headaches for callers.

  If an existing rexult is passed, return as-is rather than re-wrap it

  This would more naturally be called from, but it's an overloaded name, especially
  with Ecto.Query so this name is less invasive if imported.
  """
  @spec rexult(term()) :: t()
  def rexult(nil), do: {:error, nil}
  def rexult(:error), do: {:error, :error}
  def rexult(:ok), do: {:ok, :ok}

  def rexult({ok, a, b}) when ok in [:ok, :error] and not is_rexult(a) and not is_rexult(b) do
    # valid case for 3 tuple result, wrap 2nd & 3rd items as a 2 tuple
    {ok, {a, b}}
  end

  def rexult({:error, a, b, c}) when not is_rexult(a) and not is_rexult(b) and not is_rexult(c) do
    # 4 tuple case is ok, wrap as 2 tuple
    {:error, {a, b, c}}
  end

  def rexult({ok, val} = r) when ok in [:ok, :error] and not is_rexult(val) do
    # leave ok or error as-is, do not rewrap
    r
  end

  def rexult({:break, r} = b) when is_ok_err(r) do
    # leave break as-is, do not re-wrap
    b
  end

  def rexult(unwrapped_ok) when not is_rexult(unwrapped_ok) do
    {:ok, unwrapped_ok}
  end

  @doc """
  Assert that the value is already a result

  Auto-convert a 3 or 4 tuple error to {:error, {a, b}}
  """
  def rexult!(:error), do: {:error, :error}
  def rexult!({:error, a, b}), do: {:error, {a, b}}
  def rexult!({:error, a, b, c}), do: {:error, {a, b, c}}
  def rexult!(r) when is_rexult(r), do: r

  @doc """
  Assert that the value is not a result
  """
  def not_rexult!(val) when not is_rexult(val), do: val

  @doc """
  Construct an ok tuple

  Raise if the value passed in is already a rexult type
  """
  @spec ok!(any()) :: {:ok, any()}
  def ok!(r) when not is_rexult(r), do: {:ok, r}

  @doc """
  Wrap a non-result in an error tuple

  Will raise if already a result type
  """
  @spec err!(any()) :: {:err, any()}
  def err!(r) when not is_rexult(r) do
    {:error, r}
  end

  @doc """
  Wrap a result in a break tuple

  Breaks do not nest, max one level. Figure it out.
  """
  @spec break!(t()) :: {:break, any()}
  def break!({:break, ir} = r) when is_ok_err(ir), do: r
  def break!({:ok, ok} = r) when not is_rexult(ok), do: {:break, r}
  def break!({:error, e} = r) when not is_rexult(e), do: {:break, r}

  @doc """
  Wrap a result in an ok tuple and then a break tuple
  """
  @spec break_ok!(t()) :: {:break, {:ok, any()}}
  def break_ok!(val) do
    break!(ok!(val))
  end

  @doc """
  Take the break wrapper off the result if there is one

  Raise if it's not a result
  """
  def unbreak!({:break, r}) when is_ok_err(r), do: r
  def unbreak!({:ok, k} = r) when not is_ok_err(k), do: r
  def unbreak!({:error, e} = r) when not is_ok_err(e), do: r

  @doc """
  Unwrap a result, unbreak if necessary

  Raise if it's not ok
  """
  @spec unwrap!(term()) :: term()
  def unwrap!({:ok, ok}), do: ok

  def unwrap!({:break, b}), do: unwrap!(b)

  def unwrap!({:error, b}) do
    raise "cannot unwrap error #{inspect(b)}"
  end

  @doc """
  Unwrap an err result, unbreak if necessary

  Raise if it's not an err
  """
  @spec unwrap_err!(term()) :: term()
  def unwrap_err!({:error, err}), do: err
  def unwrap_err!({:error, err, e2}), do: {err, e2}
  def unwrap_err!({:break, b}), do: unwrap_err!(b)

  @doc """
  Check if a value is considered "ok"
  nil, :error or {:error, _} are all not ok. Everything else is ok.
  A break will return false, access it with unbreak
  """
  def ok?(r) when is_ok(r) do
    true
  end

  def ok?(r) when is_err(r) or is_break(r) do
    false
  end

  @doc """
  Check if a value is considered an error
  nil, :error or {:error, _} are all errors
  A break will return false, access it with unbreak
  """
  def err?(r) when is_err(r) do
    true
  end

  def err?(r) when is_ok(r) or is_break(r) do
    false
  end

  @doc """
  Check if a value is a break
  """
  def break?(r) when is_break(r) do
    true
  end

  def break?(r) when is_ok(r) or is_err(r) do
    false
  end

  @doc """
  Check if this value is a result
  """
  def rexult?(r) when is_ok(r) or is_err(r) or is_break(r) do
    true
  end

  @doc """
  Do one thing and if it was successful, do another thing
  """
  @spec ok_and_then(any(), fun()) :: t()
  def ok_and_then(first, second)

  def ok_and_then({:ok, ok}, then_f) when not is_rexult(ok) do
    then_f.(ok)
    |> rexult!()
  end

  def ok_and_then(:error, _second) do
    {:error, :error}
  end

  def ok_and_then({:error, _} = err, _second) do
    err
  end

  def ok_and_then({:break, _} = b, _second) do
    b
  end

  @doc """
  If a result is an error, do a different thing

  A break result falls through
  """
  @spec ok_or_else(any(), fun()) :: t()
  def ok_or_else(primary, else_f)

  def ok_or_else({:ok, _} = r, _else_f) do
    r
  end

  def ok_or_else({:error, err}, else_f) when not is_rexult(err) do
    else_f.(err)
    |> rexult!()
  end

  def ok_or_else({:break, _} = r, _f) do
    r
  end

  @doc """
  If a result is an error, do a different thing

  A break result falls through
  """
  @spec unwrap_or_else(any(), fun()) :: t()
  def unwrap_or_else(primary, else_f)

  def unwrap_or_else({:ok, ok}, _else_f) when not is_rexult(ok) do
    ok
  end

  def unwrap_or_else({:error, err}, else_f) when not is_rexult(err) do
    else_f.(err)
    |> not_rexult!()
  end

  def unwrap_or_else({:break, b}, else_f) when is_ok_err(b) do
    unwrap_or_else(b, else_f)
  end

  @doc """
  Modify a result value to another value

  Skip if the result is a break
  The ok_f function should not return an ok tuple
  """
  def map_ok(result, ok_f)

  def map_ok({:ok, r}, ok_f) when not is_rexult(r) do
    ok_f.(r)
    |> ok!()
  end

  def map_ok(:error, _ok_f) do
    {:error, :error}
  end

  def map_ok(r, _ok_f) when is_err(r) or is_break(r) do
    r
  end

  @doc """
  Modify an error value to another value

  Skip if the result is a break
  The ok_f function should not return an ok tuple
  """
  def map_err(result, err_f)

  def map_err({:ok, ok} = r, _err_f) when not is_rexult(ok) do
    r
  end

  def map_err({:error, e}, err_f) when not is_rexult(e) do
    err_f.(e)
    |> err!()
  end

  def map_err({:break, b} = r, _err_f) when is_ok_err(b) do
    r
  end

  @doc """
  Do something if a result is ok

  Return the original result unchanged, no matter what
  Useful for just reporting success or metrics
  Peek into a break result
  """
  def on_ok(result, ok_f) when is_rexult(result) do
    case unbreak!(result) do
      {:ok, val} ->
        # call the ok function on a valid value
        ok_f.(val)

      {:error, _err} ->
        # do nothing for error
        nil
    end

    result
  end

  @doc """
  Do something if a result is an error

  Return the original result unchanged, no matter what
  Useful for just reporting errors
  Peek into break result
  """
  def on_err(result, err_f) when is_rexult(result) do
    case unbreak!(result) do
      {:error, err} ->
        # call the error function on the error
        err_f.(err)

      {:ok, _ok} ->
        # ok, so do nothing
        nil
    end

    result
  end

  @doc """
  Given a list of results, keep only those that are ok
  """
  def filter_ok(results) when is_list(results) do
    Enum.filter(results, &ok?/1)
    |> Enum.map(&unwrap!/1)
  end

  @doc """
  Given a list of results, keep only those that are err
  """
  def filter_err(results) when is_list(results) do
    Enum.filter(results, &err?/1)
    |> Enum.map(&unwrap_err!/1)
  end

  @doc """
  Split a list of results into those that are ok and those that are errors

  The ok values and errors are both unwrapped within their new lists
  Both lists are always returned, even if they are empty
  """
  @spec split_ok_err([t()]) :: {[t()], [t()]}
  def split_ok_err(results) when is_list(results) do
    {oks, errs} = Enum.split_with(results, &ok?/1)
    uoks = Enum.map(oks, &unwrap!/1)
    uerrs = Enum.map(errs, &unwrap_err!/1)
    {uoks, uerrs}
  end

  @doc """
  Given a list of results, ok with list of ok values

  Else return the first error found
  """
  def all_ok(results) when is_list(results) do
    case Enum.find(results, &err?/1) do
      {:error, _} = e -> e
      nil -> Enum.map(results, &unwrap!/1) |> ok!()
    end
  end

  @doc """
  Deprecated
  """
  def is_rexult!(r), do: rexult!(r)

  ### MACROS

  @doc """
  Do one thing and if it's successful, do another thing that returns a rexult
  """
  defmacro ok_and(primary, do: next) do
    quote do
      presult = unquote(primary)

      if Rexult.ok?(presult) do
        Rexult.is_rexult!(unquote(next))
      else
        presult
      end
    end
  end

  defmacro ok_and(primary, next) do
    quote do
      presult = unquote(primary)

      if Rexult.ok?(presult) do
        Rexult.is_rexult!(unquote(next))
      else
        presult
      end
    end
  end

  @doc """
  Do one thing and if it's not successful, do a different thing

  The result of primary must already be a result. Convert w/ `rexult` if necessary.
  """
  defmacro ok_or(primary, do: alt) do
    quote do
      presult = unquote(primary)

      if Rexult.err?(presult) do
        Rexult.is_rexult!(unquote(alt))
      else
        presult
      end
    end
  end

  defmacro ok_or(primary, alt) do
    quote do
      presult = unquote(primary)

      if Rexult.err?(presult) do
        Rexult.is_rexult!(unquote(alt))
      else
        presult
      end
    end
  end

  @doc """
  Get the thing if it was successful, else get a different thing
  """
  defmacro unwrap_or(primary, do: alt) do
    quote do
      presult =
        unquote(primary)
        |> unbreak!()

      case presult do
        {:ok, r} ->
          r

        {:error, _} ->
          unquote(alt)
      end
    end
  end

  defmacro unwrap_or(primary, alt) do
    quote do
      presult =
        unquote(primary)
        |> unbreak!()

      case presult do
        {:ok, r} ->
          r

        {:error, _} ->
          unquote(alt)
      end
    end
  end
end
