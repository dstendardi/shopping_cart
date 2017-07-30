defmodule Acme.Shopping.Order do

  @moduledoc """
  Represent an order. An order contains a list of order items.
  It serves as a facade for interacting with order items
  and price computation resulting from promotions.
  """

  use Ecto.Schema
  import Ecto.{Changeset}
  alias Acme.Shopping.{Order, OrderItem, PricingPolicy}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "orders" do
    has_many :items, OrderItem
    timestamps()
  end

  @doc false
  def changeset(%Order{} = order, attrs) do

    order
    |> cast(attrs, [])
    |> Ecto.Changeset.cast_assoc(:items)
  end

  @doc """
  Create a new empty order.
  Order is peristed at the very begining of the checkout process.
  """
  def create() do

    %Order{}
    |> Order.changeset(%{items: []})
    |> Acme.Repo.insert!()
  end

  @doc """
  Add a product to the order using upsert.
  We relay on constraints to ensure the product exists.

  If product or order are missing, it will throw a changset error
  Items are always added to the order one buy one
  """
  def add(order, product_id) do

    %OrderItem{}
    |> OrderItem.changeset(%{product_id: product_id,  order_id: order.id, quantity: 1})
    |> Acme.Repo.insert!(on_conflict: [inc: [quantity: 1]], conflict_target: [:product_id, :order_id])

    order
  end

  @doc """
  Perform the actual price computation using order_items.
  """
  def price(%{id: order_id}) do

    order_id
      |> OrderItem.price_and_quantity_by_item()
      |> Acme.Repo.all()
      |> Enum.reduce(%{}, &price_per_product_with_rule/2)
      |> Enum.reduce(0, &apply_rule/2)
  end

  defp price_per_product_with_rule({product_id, rule, price, quantity}, acc) do
    Map.put(acc, product_id, {price, quantity, rule})
  end

  defp apply_rule({_, {price, quantity, rule}}, acc) do
    acc + PricingPolicy.apply_rule(rule, {price, quantity})
  end
end
