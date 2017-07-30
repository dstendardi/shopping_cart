defmodule Acme.Shopping.Promotion do

  @moduledoc """
  A promotion is an association between  pricing policies and products

  We chose to name it with a specific entity name because it will probably evolve into something more complex as
  the product grows (start / end date for example)

  Also we use a many to many relationship in order to anticipate the need for associating a pricing policy to several
  products at the same time.
  """

  use Ecto.Schema
  import Ecto.{Changeset}
  alias Acme.Shopping.{Promotion, PricingPolicy, Product}

  @primary_key false
  @foreign_key_type :binary_id

  schema "promotions" do
    belongs_to :pricing_policy, PricingPolicy
    belongs_to :product, Product

    timestamps()
  end

  @doc false
  def changeset(%Promotion{} = promotion, attrs) do
    promotion
    |> cast(attrs, [:product_id, :pricing_policy_id])
    |> validate_required([:product_id, :pricing_policy_id])
    |> foreign_key_constraint(:pricing_policy_id)
    |> foreign_key_constraint(:product_id)
  end
end
