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

  @doc """
  Unwrap an ok value into an {:ok, tuple} or return the error in an {:error, tuple}

  The cases of :ok -> {:ok, :ok} and :error -> {:error, :error} are a little weird
  But they normalize the output, so going to stick with it.
  Converting them to any other value will be misleading and leaving them
  as bare :ok or :error will cause match case headaches for callers.

  This would more naturally be called from, but it's an overloaded name, especially
  with Ecto.Query so this name is less invasive if imported.
  """
  @spec rexult(term()) :: t()
  def rexult(nil), do: {:error, nil}
  def rexult(:error), do: {:error, :error}
  def rexult(:ok), do: {:ok, :ok}

  def rexult({:error, _} = _err) do
    raise "result is error"
  end

  def rexult({:ok, _} = _ok) do
    raise "result is ok"
  end

  def rexult({:break, _} = _b) do
    raise "result is break"
  end

  def rexult(unwrapped_ok), do: {:ok, unwrapped_ok}

  @spec ok!(any()) :: {:ok, any()}
  def ok!({:ok, _ok}) do
    raise "result is ok"
  end

  def ok!({:error, _err}) do
    raise "error result not ok"
  end

  def ok!(:error) do
    raise "error not ok"
  end

  def ok!({:break, _b}) do
    raise "break result not ok"
  end

  def ok!(r), do: {:ok, r}

  @doc """
  Wrap a non-result in an error tuple

  Will raise if already a result type
  """
  @spec err!(any()) :: {:err, any()}
  def err!({:error, _err}) do
    raise "result is error"
  end

  def err!({:ok, _err}) do
    raise "ok result is not error"
  end

  def err!(:ok) do
    raise "ok is not error"
  end

  def err!({:break, _b}) do
    raise "break result not error"
  end

  def err!(r), do: {:error, r}

  @doc """
  Wrap a result in a break tuple

  Breaks do not nest, max one level. Figure it out.
  """
  @spec break!(t()) :: {:break, any()}
  def break!({:break, _} = r), do: r
  def break!({:ok, _} = r), do: {:break, r}
  def break!({:error, _} = r), do: {:break, r}

  def break!(_r) do
    raise "break must be result"
  end

  @doc """
  Take the break wrapper off the result if there is one
  """
  def unbreak({:break, {:ok, _} = r}), do: r
  def unbreak({:break, {:error, _} = r}), do: r
  def unbreak({:ok, _} = r), do: r
  def unbreak({:error, _} = r), do: r

  def unbreak({:break, _r}) do
    raise "invalid break"
  end

  @doc """
  Unwrap a result
  """
  @spec unwrap!(term()) :: term()
  def unwrap!({:ok, ok}), do: ok
  def unwrap!(nil), do: raise("unwrap nil")
  def unwrap!(:error), do: raise("unwrap error atom")
  def unwrap!({:error, _}), do: raise("unwrap error")
  def unwrap!({:break, b}), do: unwrap!(b)

  @doc """
  Unwrap an err result
  """
  @spec unwrap_err!(term()) :: term()
  def unwrap_err!({:error, err}), do: err
  def unwrap_err!(nil), do: raise("unwrap_err nil")
  def unwrap_err!({:ok, _}), do: raise("unwrap_err ok")
  def unwrap_err!(:error), do: raise("unwrap_err error atom")
  def unwrap_err!({:break, b}), do: unwrap_err!(b)

  @doc """
  Check if a value is considered "ok"
  nil, :error or {:error, _} are all not ok. Everything else is ok.
  A break will return false, access it with unbreak
  """
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false
  def ok?({:break, {:ok, _}}), do: false

  @doc """
  Check if a value is considered an error
  nil, :error or {:error, _} are all errors
  A break will return false, access it with unbreak
  """
  def err?({:error, _}), do: true
  def err?({:ok, _}), do: false
  def err?({:break, _}), do: false

  @doc """
  Do one thing and if it was successful, do another thing
  """
  @spec ok_and_then(any(), fun()) :: t()
  def ok_and_then(first, second) do
    case first do
      {:ok, ok} ->
        second.(ok)
        |> is_result!()

      {:error, _} = err ->
        err

      {:break, _} = b ->
        b
    end
  end

  @doc """
  If a result is an error, do a different thing

  A break result falls through
  """
  @spec ok_or_else(any(), fun()) :: t()
  def ok_or_else(primary, else_f) do
    case primary do
      {:ok, _} = r ->
        r

      {:error, err} ->
        else_f.(err)
        |> is_result!()

      {:break, _} = b ->
        b
    end
  end

  @doc """
  Modify a result value to another value

  Skip if the result is a break
  The ok_f function should not return an ok tuple
  """
  def map_ok(result, ok_f) do
    case result do
      {:ok, r} ->
        ok_f.(r)
        |> ok!()

      {:error, _} = e ->
        e

      {:break, _} = b ->
        b
    end
  end

  @doc """
  Modify an error value to another value

  Skip if the result is a break
  The ok_f function should not return an ok tuple
  """
  def map_err(result, err_f) do
    case result do
      {:ok, _} = ok ->
        ok

      {:error, err} ->
        err_f.(err)
        |> err!()

      {:break, _} = b ->
        b
    end
  end

  @doc """
  Do something if a result is ok

  Return the original result unchanged, no matter what
  Useful for just reporting success or metrics
  Peek into a break result
  """
  def on_ok(result, ok_f) do
    case unbreak(result) do
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
  def on_err(result, err_f) do
    case unbreak(result) do
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
  def filter_ok(results) do
    Enum.filter(results, &ok?/1)
    |> Enum.map(&unwrap!/1)
  end

  @doc """
  Given a list of results, keep only those that are err
  """
  def filter_err(results) do
    Enum.filter(results, &err?/1)
    |> Enum.map(&unwrap_err!/1)
  end

  @doc """
  Given a list of results, find an error if there is one

  Else wrap the results as an ok result
  """
  def find_err(results) do
    case Enum.find(results, &err?/1) do
      {:error, _} = e -> e
      nil -> filter_ok(results) |> ok!()
    end
  end

  @doc """
  Assert that the value is already a result
  """
  def is_result!({:ok, _} = r), do: r
  def is_result!({:error, _} = r), do: r
  def is_result!({:break, _} = r), do: r

  def is_result!(_) do
    raise "is not result"
  end

  ### MACROS

  @doc """
  Do one thing and if it's successful, do another thing that returns a rexult
  """
  defmacro ok_and(primary, do: next) do
    quote do
      presult = unquote(primary)

      if Rexult.ok?(presult) do
        Rexult.is_result!(unquote(next))
      else
        presult
      end
    end
  end

  defmacro ok_and(primary, next) do
    quote do
      presult = unquote(primary)

      if Rexult.ok?(presult) do
        Rexult.is_result!(unquote(next))
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
        Rexult.is_result!(unquote(alt))
      else
        presult
      end
    end
  end

  defmacro ok_or(primary, alt) do
    quote do
      presult = unquote(primary)

      if Rexult.err?(presult) do
        Rexult.is_result!(unquote(alt))
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
        |> unbreak()

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
        |> unbreak()

      case presult do
        {:ok, r} ->
          r

        {:error, _} ->
          unquote(alt)
      end
    end
  end
end
