defmodule Acme.Shopping.OrderItem do

  @moduledoc """
  Represents an association between an order and a product.
  When user  add several time the same product to the order, the
  quantity field is incremented using an upsert.

  Performance consideration :
  If we have 100K active users adding an average of 3 items per shopping cart
  this will result in 300K associations rows (still a very low number for postgres).

  If we reach some limitations, we adopt serveral solutions including :
    * make use of jsonb and stick to ecto : this would reduce the number of query we are doing for validation
      and simplify the code. However, we would lose efficiency at query time and constraints checks.
    * if we are hosted on aws : use dynamodb and leverage the upsert features (including condtional checks for validation)
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Acme.Shopping.{OrderItem, Product, Promotion, PricingPolicy}

  @primary_key false
  schema "order_items" do

    field :order_id, :binary_id, primary_key: true
    field :product_id, :binary_id, primary_key: true

    belongs_to :order, Acme.Shopping.Order, define_field: false
    belongs_to :product, Acme.Shopping.Product, define_field: false

    field :quantity, :integer
    timestamps()
  end

  @doc """
  To be valid the changeset should :
    * contains all required attributes (quantity, product_id, order_id)
    * check the constraints exists (in case some product is deleted for example)
    * check we do not exeed limits of items per order
  """
  def changeset(%OrderItem{} = order_item, attrs) do
    order_item
      |> cast(attrs, [:quantity, :product_id, :order_id])
      |> validate_required([:quantity, :product_id, :order_id])
      |> foreign_key_constraint(:product_id)
      |> foreign_key_constraint(:order_id)
      |> validate_number(:quantity, greater_than: 0)
      |> validate_number_of_items()
      |> validate_quantity()
  end

  @doc """
  Ensure we do not exceed the maximum number of items
  this limit was chosen after amazon shopping cart limits
  see : https://www.amazon.com/forum/gift%20idea?_encoding=UTF8&cdForum=Fx1CXJAP860ADZ8&cdThread=Tx25YBBUU9ET5J8

  When changeset is invalid, this validator is skipped
  Therefor it must be added after basic requirement checks
  """
  def validate_number_of_items(%{valid?: false} = changeset), do: changeset
  def validate_number_of_items(%{params: %{"order_id" => order_id}} = changeset) do

    max_item_per_order = Application.get_env(:acme, :max_item_per_order)

    current_item_count = Acme.Repo.one(
      from item in OrderItem,
        select: count("*"),
        where: item.order_id == ^order_id
    )

    if is_number(current_item_count) and current_item_count >= max_item_per_order do
      add_error(changeset, :order_id, "Too many products")
    else
      changeset
    end

  end

  @doc """
  Ensure we do not exceed the max quantity per items
  see : https://www.amazon.com/forum/gift%20idea?_encoding=UTF8&cdForum=Fx1CXJAP860ADZ8&cdThread=Tx25YBBUU9ET5J8

  When changeset is invalid, this validator is skipped
  It must be added after basic requirements checks
  """
  def validate_quantity(%{valid?: false} = changeset), do: changeset
  def validate_quantity(%{
    params: %{
      "order_id" => order_id,
      "product_id" => product_id,
      "quantity" => quantity
    }} = changeset) do

    max_quantity_per_item = Application.get_env(:acme, :max_quantity_per_item)

    current_quantity = Acme.Repo.one(
      from item in OrderItem,
      select: item.quantity,
      where: item.order_id == ^order_id and item.product_id == ^product_id
    )

    # didn't find yet a better way to sanitize in ecto
    current_quantity = if is_nil(current_quantity), do: 0, else: current_quantity

    if current_quantity + quantity >= max_quantity_per_item do
      add_error(changeset, :quantity, "Too many items for product")
    else
      changeset
    end
  end

  @doc """
  Returns for each order items a tuple containing
    * product id
    * price
    * quantity

  The result of this function is used to compute
  the final price
  """
  def price_and_quantity_by_item(order_id) do

    from u in OrderItem,
      where: u.order_id == ^order_id,
      join: product in Product, on: [id: u.product_id],
      left_join: promotion in Promotion, on: [product_id: product.id],
      left_join: pricing_policy in PricingPolicy, on: [id: promotion.pricing_policy_id],
      select: {product.id, pricing_policy.rule, product.price, u.quantity}
  end
end
