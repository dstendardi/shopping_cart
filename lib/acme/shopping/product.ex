defmodule Acme.Shopping.Product do

  @moduledoc """
  Represent a product in our model. A product contains
    * a price reference, right now implicitly using euro for money.
    * a name (unique) used to describe the product.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Acme.Shopping.Product

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :name, :string
    field :price, :float

    timestamps()
  end

  @doc false
  def changeset(%Product{} = product, attrs) do
    product
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than: 0)
  end
end
