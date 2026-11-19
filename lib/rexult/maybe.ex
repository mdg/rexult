defmodule Rexult.Maybe do
  def and_then(m, f)

  def and_then(nil, _f) do
    nil
  end

  def and_then(m, f) do
    f.(m)
  end

  @doc """
  If the maybe val is not nil and the boolen is true, return the result of the function
  """
  def and_if(m, b, f)

  def and_if(nil, b, _f) when is_boolean(b) do
    nil
  end

  def and_if(m, false, _f) do
    m
  end

  def and_if(m, true, f) do
    f.(m)
  end

  @doc """
  If both maybe vals are not nil, call the given function

  If either is nil, return the first value unchanged
  """
  def and_both(m, other, f)

  def and_both(nil, _other, _f) do
    nil
  end

  def and_both(m, nil, _f) do
    m
  end

  def and_both(m, other, f) do
    f.(m, other)
  end

  @doc """
  If the first value is nil, return the default, else keep the original value
  """
  def or_default(m, d)
  def or_default(nil, d), do: d
  def or_default(m, _d), do: m

  def or_else(m, f)

  def or_else(nil, f) do
    f.()
  end

  def or_else(m, _f) do
    m
  end
end
